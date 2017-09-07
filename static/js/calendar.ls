Vue.component 'time-ribbon' do
  # One of these just for now
  template: '''
  <div :style="style"></div>
  '''
  data: -> store: window.availability-store
  computed:
    shouldShow: -> moment!.isSame @store.attention-day, 'd'
    minute: -> window.availability-store.now-minute
    style: ->
      position: "absolute"
      height: "6px"
      top: ""+(@minute * 32.0 / 60 ) + "px"
      width: "100%"
      background: '\#b31b1b'
      borderTop: "solid 2px \#fff"
      borderBottom: "solid 2px \#fff"

Vue.component 'time-square' do
  # Each hour gets one of these
  template: '''
  <div
    :style="style"
    @mouseover="mouseover()"
  >{{label}}</div>
  '''
  props: ['hour', 'loaded', 'label']
  data: -> store: window.availability-store
  methods:
    mouseover: ->
      @store.highlight-half-hour-block @hour
  computed:
    selected: ->
      # Intersect the selection with my half-hour block
      @store.time-selected @hour*60, @hour*60+30
    style: ->
      height: "16px"
      max-height: "16px"
      min-width: "3em"
      background:
        if @selected
          "url(#{BACKGROUND_LOADING})"
        else
          if @loaded then null else "url(#{BACKGROUND_LOADING})"
      borderTop: if @loaded then "solid 1px \##{if this.hour % 1 then 'eee' else '000'}" else ""
      overflow: "hidden"
Vue.component 'time-square-event' do
  # Shows one event on somebody's calendar
  template: '''
    <div :style="style">
      {{start.local().format('h:mm')}}
      to
      {{end.local().format('h:mm')}}
    </div>
  '''
  props: ['start', 'end']
  computed:
    startMinutes: -> moment-to-midnight-minutes @start
    endMinutes: -> moment-to-midnight-minutes @end
    style: ->
      position: "absolute"
      margin: "0 0.5em"
      backgroundColor: CORNELL_TECH_RED
      border-radius: "4px"
      color: "\#fff"
      top: ""+(@startMinutes * 32.0 / 60 ) + "px"
      height: ""+((@endMinutes-@startMinutes) * 32.0 / 60 ) + "px"
      max-height: ""+((@endMinutes-@startMinutes) * 32.0 / 60 ) + "px"
      overflow: "hidden"

Vue.component 'show-timeslice' do
  # Rendered timeslice
  template: '''
  <div>
     <div class="square" style="position: relative;">
       <time-square
         :hour="hour"
         :loaded="loaded && !errorMessage"
         :label="renderHour(hour)"
         v-for="hour in timeslices"
         ></time-square>
       <time-ribbon></time-ribbon>
       <time-square-event
         v-bind="event"
         v-for="event in events"></time-square-event>
     </div>
  </div>
  '''
  props: ['events', 'loaded', 'showHours', 'errorMessage']
  data: ->
    timeslices: [0 til 24 by 0.5]
  methods:
    renderHour: (hour) ->
      if @showHours and hour == parseInt hour
        moment(hour, "H").format "h"
  computed:
    nowMinute: -> moment-to-midnight-minutes(moment())

Vue.component 'room-availability-timeslice' do
  template: '''
    <show-timeslice
      :events="events" :loaded="loaded"
      ></show-timeslice>
  '''
  props: ['netid']
  data: -> store: window.availability-store
  computed:
    events: -> @availability.events
    loaded: -> @availability.loaded
    errorMessage: -> @availability.errorMessage
    availability: -> @store.load-availability @netid

Vue.component 'calendar' do
  template: '''
    <div>
      <div class="app-header">
        <h1 class="wide">
          Availability
          <button class="btn" @click="expand" v-if="showButton">
            <i v-if="!expanded" class="fa fa-lg fa-eye"></i>
            <i v-if="expanded" class="fa fa-lg fa-eye-slash"></i>
            {{expanded? "Hide entire floor" : "Show entire floor"}}
          </button>
        </h1>
      </div>
      <table>
        <tr>
          <th class="open">Room </th>
          <th v-for="room in roomsToShow">
              <a :class="{selected: isSelected(room)}"
                  href="#" @click="click(room)">
                {{roomShortname[room]}}
                <i v-if="isSelected(room)" class="fa fa-check"></i>
              </a>
          </th>
        </tr>
        <tr>
          <td>
            <show-timeslice showHours="true" loaded="true"></show-timeslice>
          </td>
          <td v-for="room in roomsToShow">
            <room-availability-timeslice :netid="room"></room-availability-timeslice>
          </td>
        </tr>
      </table>
    </div>
  '''
  data: ->
    store: availability-store
    room-shortname: ROOMID_TO_SHORTNAME
    expanded: false
  methods:
    expand: -> @expanded = !@expanded
    click: (room) -> @store.select-room room
    is-selected: (room) -> @store.selected-room == room
  computed:
    show-button: -> false
    #show-button: -> @selected-room and @store.attention-rooms.length >= 2
    selected-room: -> @store.selected-room
    rooms-to-show: ->
      expanded-rooms = if not @selected-room or @expanded then @store.attention-rooms else []
      if @selected-room
        [@selected-room] ++ expanded-rooms
      else
        expanded-rooms
