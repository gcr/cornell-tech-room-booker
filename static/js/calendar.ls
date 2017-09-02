Vue.component 'time-ribbon' do
  # One of these just for now
  template: '''
  <div :style="style"></div>
  '''
  data: -> store: window.availability-store
  computed:
    minute: -> window.availability-store.now-minute
    style: ->
      position: "absolute"
      height: "3px"
      top: ""+(@minute * 32.0 / 60 ) + "px"
      width: "100%"
      background: '\#1bb31b'
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
      height: "15px"
      max-height: "15px"
      width: "5em"
      background:
        if @selected
          "url(#{BACKGROUND_LOADING})"
        else
          if @loaded then null else "url(#{BACKGROUND_LOADING})"
      borderTop: "solid 1px \##{if this.hour % 1 then 'eee' else 'e38b8b'}"
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
      width: "4em"
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
  props: ['events', 'errorMessage', 'loaded', 'showHours']
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
    <show-timeslice v-bind="store.loadAvailability(netid)"></show-timeslice>
  '''
  props: ['netid']
  data: -> store: window.availability-store

Vue.component 'timeslice-table' do
  template: '''
    <table>
      <tr>
        <td></td>
        <td v-for="room in rooms">{{roomShortname[room]}}</td>
      </tr>
      <tr>
        <td>
          <show-timeslice showHours="true" loaded="true"></show-timeslice>
        </td>
        <td v-for="room in rooms">
          <room-availability-timeslice :netid="room"></room-availability-timeslice>
        </td>
      </tr>
    </table>
  '''
  props: ['rooms']
  computed:
    room-shortname: -> window.ROOM_ID_TO_SHORTNAME
