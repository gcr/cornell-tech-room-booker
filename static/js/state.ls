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

export class AvailabilityStore
  # Global state.
  # NOTE: All state transitions must be Vue-compatible, so
  # when adding/removing hash keys, use Vue.set etc
  ->
    # Attention set: List of room availabilities to show
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
    @cached-availability = {} # <-- Do not use externally
    @query-debounce-rooms = {}
    @query-server-promise = null

  highlight-half-hour-block: (hour) ->
    @current-time-range.start = hour * 60
    @current-time-range.end = hour * 60 + 30
    @update-attention-room-status!

  # Returns an object that contains the room's availability. It's safe
  # to bind views to the result; the result is reactive and will
  # be mutated once the room is loaded.
  load-availability: (room-netid) ->
    if room-netid not of @cached-availability
      Vue.set @cached-availability, room-netid, loaded: false, events: [], errorMessage: ""
      # This room needs to be loaded, so debounce it
      @query-debounce-rooms[room-netid] = true
      @query-server-for-availabilities!
    @cached-availability[room-netid]

  promise-availability: (room-netid) ->

  bump-attention-day: (range) ->
    @attention-day = moment(@attention-day.add range, 'day')
    @cached-availability = {}
    # ^ a bit surprised that this here works, but i'm replacing the
    # value completely. (i think this will work as long as views don't
    # bind to the object directly, which they shouldn't)
    @set-attention-rooms [r for r in @attention-rooms]

  # Maybe query the server for all debounced rooms.
  query-server-for-availabilities: ->
    if @query-server-promise
      @query-server-promise
    else
      @query-server-promise = new Promise (resolve,reject) ~>
        <~ set-timeout _, 100
        $.ajax do
          data-type: 'json'
          method: 'POST'
          url: '/availability'
          data: do
            rooms: [room for room,_ of @query-debounce-rooms]
            date-string: @attention-day.format!
          error: (err) ~>
            @query-debounce-rooms = {}
            @query-server-promise = null
            reject err
          success: ({ok, err}) ~>
            @query-debounce-rooms = {}
            @query-server-promise = null
            if err
              reject err
            else
              for room-id, {errorMessage, events} of ok
                @cached-availability[room-id].errorMessage = errorMessage
                @cached-availability[room-id].loaded = true
                # Need to preserve Vue reactivity
                old-events = @cached-availability[room-id].events
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
    # Keep Vue reactivity
    for roomid in @attention-rooms
      Vue.delete @attention-room-status, roomid
      availability = @load-availability roomid
      if not availability.loaded
        Vue.set @attention-room-status, roomid, "Loading"
      else
        Vue.set @attention-room-status, roomid, "Available"
        for event in availability.events
          if @event-selected event
            Vue.set @attention-room-status, roomid, "Booked"

  set-attention-rooms: (new-room-ids) ->
    # Keep Vue reactivity. (Some views may bind to @attention-rooms
    # itself)
    @attention-rooms.splice 0
    for id in new-room-ids
      @attention-rooms.push id
    @update-attention-room-status!
  set-attention-floor: (new-floor-name) -> @attention-floor = new-floor-name

export availability-store = new AvailabilityStore!

#setInterval (-> availability-store.now-minute = 60*24*Math.random!), 1500
