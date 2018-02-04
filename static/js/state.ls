parse-events-to-moments = (events, which-day) ->
  # Return [{start: ..., end: ...}, ...]
  # Slice the portions of this event that overlap with today

  result-events = []
  for {start, end, busy} in events
    this-morning = moment(which-day).start-of 'day'
    this-evening = moment(which-day).end-of 'day'

    start = moment.utc(start)
    end = moment.utc(end)

    end-intersection = moment.min(end, this-evening)
    start-intersection = moment.max(start, this-morning)
    if end-intersection.diff(start-intersection) > 0
      result-events.push do
        start: start-intersection
        end: end-intersection
  result-events

export moment-to-midnight-minutes = (point) ->
  point.diff(moment(point).local!.start-of 'day') / 1000.0 / 60.0

make-current-time-range = ->
  now-minutes = moment-to-midnight-minutes(moment!)
  start-minutes = Math.floor(now-minutes / 30.0) * 30.0
  start: start-minutes, end: start-minutes + 30

batch-function-calls-into-list = (timeout, f) ->
  # Batch up groups of f(1), f(2), f(3) calls into f([1,2,3])
  args = []
  timer = null
  return (x) ->
    args.push x
    if timer is null
      timer := setTimeout (-> f args), timeout


export class AvailabilityStore
  # Global state.
  # NOTE: All state transitions must be Vue-compatible, so
  # when adding/removing hash keys, use Vue.set etc
  ->
    # Attention set: List of room availabilities to show today.
    @attention-rooms = []
    @attention-room-status = {}

    # Selected room, if any
    @selected-room = null

    # Current floor, if any. Only used by the map view. Doesn't
    # influence anything.
    @attention-floor = null

    # Currently-considered time range, in minutes on the current day
    @current-time-range = make-current-time-range!

    # What day to show events from
    @attention-day = moment!

    # When to show the time ribbon
    @now-minute = moment-to-midnight-minutes moment!

    # Caching (internal)
    @cached-room-data = {} # <-- Do not use externally
    @query-debounce-rooms = []
    @query-server-promise = null

  highlight-half-hour-block: (hour) ->
    @current-time-range.start = hour * 60
    @current-time-range.end = hour * 60 + 30
    @update-attention-room-status!

  # Returns an object that contains the room's room-data. It's safe
  # to bind views to the result; the result is reactive and will
  # be mutated once the room is loaded.
  load-room-data: (room-netid) ->
    unique-room-id = @attention-day.format! + room-netid
    if unique-room-id not of @cached-room-data
      Vue.set @cached-room-data, unique-room-id, loaded: false, events: [], errorMessage: "", date: @attention-day.format!
      # This room needs to be loaded, so debounce it
      @query-debounce-rooms.push netid: room-netid, date: @attention-day.format!, unique-room-id: unique-room-id
      @query-server-for-availabilities!
    @cached-room-data[unique-room-id]

  bump-attention-day: (range) ->
    @query-server-promise = null
    @query-debounce-rooms = []
    @attention-day = moment(@attention-day.add range, 'day')
    @cached-room-data = {}
    # ^ a bit surprised that this here works, but i'm replacing the
    # value completely. (i think this will work as long as views don't
    # bind to the object directly, which they shouldn't)
    old-selected-room = @selected-room
    @set-attention-rooms [r for r in @attention-rooms]
    @selected-room = old-selected-room

  # Maybe query the server for all debounced rooms.
  query-server-for-availabilities: ->
    if @query-server-promise
      @query-server-promise
    else
      @query-server-promise = new Promise (resolve,reject) ~>
        <~ set-timeout _, 100
        date = @attention-day.format!
        console.log "Retrieving rooms for", date
        room-netid-hash = {[data.netid, true] for id,data of @query-debounce-rooms}
        room-netids = [netid for netid,_ of room-netid-hash]
        $.ajax do
          data-type: 'json'
          method: 'POST'
          url: '/availability'
          data: do
            rooms: room-netids
            date-string: date
          error: (err) ~>
            @query-debounce-rooms = []
            @query-server-promise = null
            reject err
          success: ({ok, err}) ~>
            @query-debounce-rooms = []
            @query-server-promise = null
            if err
              reject err
            else
              console.log date, @cached-room-data
              for room-netid, {errorMessage, events} of ok
                unique-room-id = date + room-netid
                # Only update this room if the current day is the one the
                # query is waiting for. If several queries are in
                # flight (the user clicks Next Day quickly enough),
                # the last one wins, which isn't what we want.
                if unique-room-id of @cached-room-data
                  @cached-room-data[unique-room-id].errorMessage = errorMessage
                  @cached-room-data[unique-room-id].loaded = true
                  # Need to preserve Vue reactivity
                  old-events = @cached-room-data[unique-room-id].events
                  old-events.splice 0
                  for ev in parse-events-to-moments events, @attention-day
                    old-events.push ev
                  @update-attention-room-status!
              resolve!

  time-selected: (start-min, end-min) ->
      Math.max(
        @current-time-range.start, start-min
      ) < Math.min(
        @current-time-range.end, end-min
      )

  event-selected: ({start, end}) ->
    @time-selected moment-to-midnight-minutes(start), moment-to-midnight-minutes(end)

  update-attention-room-status: ->
    # Populates @attention-room-status[roomid] to indicate whether
    # this room is Available, Booked, or Loading at the time of
    # the current hour selection

    # Keep Vue reactivity
    for roomid in @attention-rooms
      Vue.delete @attention-room-status, roomid
      room-data = @load-room-data roomid
      if not room-data.loaded
        Vue.set @attention-room-status, roomid, "Loading"
      else
        Vue.set @attention-room-status, roomid, "Available"
        for event in room-data.events
          if @event-selected event
            Vue.set @attention-room-status, roomid, "Booked"

  set-attention-rooms: (new-room-ids) ->
    # Keep Vue reactivity. (Some views may bind to @attention-rooms
    # itself)
    @select-room null
    @attention-rooms.splice 0
    for id in new-room-ids
      @attention-rooms.push id
    @update-attention-room-status!
  set-attention-floor: (new-floor-name) -> @attention-floor = new-floor-name

  select-room: (roomid) ->
    if @selected-room == roomid
      @selected-room = null
    else
      @selected-room = roomid

export availability-store = new AvailabilityStore!

#setInterval (-> availability-store.now-minute = 60*24*Math.random!), 1500
