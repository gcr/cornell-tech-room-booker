export CORNELL_TECH_RED = "\#b31b1b"

export BACKGROUND_LOADING = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAYAAADgzO9IAAAAIUlEQVQYV2PcLC393/fpU0YGNIAhAJMnTgLZWOJ0INsPADIQCAdlTP30AAAAAElFTkSuQmCC"

export BACKGROUND_LOADING = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAKElEQVQYV2NkQAObpaX/MyKLgQR8nz5lhAvCBECKwILIAmBBdAGQIABEwxHu9sr/MwAAAABJRU5ErkJggg=="

Vue.component 'active-floorplan' do
  template: '''
  <floorplan :roomStatus="roomStatus" :floorid="floorid"></floorplan>
  '''
  props: ['rooms', 'floorid']
  data: -> store: window.availability-store
  methods: compute-activity: (room) ->
    if room.loaded
      for evt in room.events
        if @store.event-selected evt
          return "red"
      "green-outline"
    else
      "red-hatch"
  computed:
    roomStatus: ->
      roomStatus = {}
      for room in @rooms
        roomStatus[room] = @compute-activity @store.load-availability(room)
      roomStatus

Vue.component 'floor-list' do
  template: '''
  <ul>
    <li v-for="floor in floorlist">
      <h2>
        <a href="#"@click="selectFloor(floor)">(Select)</a>
        {{floor.name}}
      </h2>
    </li>
  </ul>
  '''
  data: ->
    floorlist: FLOOR_LIST
    current-floor: null
    store: availability-store
  methods:
    selectFloor: (floor) ->
      @current-floor = floor.name
      all-room-ids = [r.id for r in floor.rooms]
      @store.set-attention-floor floor.name
      @store.set-attention-rooms all-room-ids

Vue.component 'room-list' do
  template: '''
  <ul>
    <li v-for="roomid in attentionRooms">
      {{roomName[roomid]}} ({{status[roomid]}})
    </li>
  </ul>
  '''
  data: ->
    attentionRooms: availability-store.attentionRooms
    roomName: ROOMID_TO_NAME
    status: availability-store.attentionRoomStatus

#Vue.component 'room-listing' do
#  template: '''
#  <div style="display: flex; flex-wrap: nowrap;">
#    <ul>
#      <li v-for="floor in floorlist">
#        <h1>{{floor.name}} <a href="#" @click="view(floor)">(View)</a></h1>
#        <ul>
#          <li v-for="room in floor.rooms">{{room.name}}</li>
#        </ul>
#      </li>
#    </ul>
#    <div style="width: 100; max-height: 100%;">
#    <active-floorplan
#      :floorid="viewingFloor"
#      :rooms="viewingRooms"></active-floorplan>
#    </div>
#    <timeslice-table :rooms="viewingRooms"></timeslice-table>
#  </div>
#  '''
#  methods:
#    view: (floor) ->
#      @viewing-floor = floor.name
#  computed:
#    floorlist: -> FLOOR_LIST
#    viewing-rooms: -> [room.id for floor in FLOOR_LIST when floor.name == @viewing-floor for room in floor.rooms]
#  data: ->
#   selected-rooms: []
#   viewing-floor: ""


Vue.component 'app' do
 template: '''
 <div>
   <floor-list></floor-list>
   <room-list></room-list>
   <floorplan></floorplan>
 </div>
 '''


$ ->
  @app = new Vue el: '#myapp'
