export CORNELL_TECH_RED = "\#b31b1b"

export BACKGROUND_LOADING = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAYAAADgzO9IAAAAIUlEQVQYV2PcLC393/fpU0YGNIAhAJMnTgLZWOJ0INsPADIQCAdlTP30AAAAAElFTkSuQmCC"

export BACKGROUND_LOADING = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAKElEQVQYV2NkQAObpaX/MyKLgQR8nz5lhAvCBECKwILIAmBBdAGQIABEwxHu9sr/MwAAAABJRU5ErkJggg=="

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

Vue.component 'date-scrubber' do
  template: '''
  <div>
    <a href="#" @click="backward">Prev</a>
    <h2>{{date}}</h2>
    <a href="#" @click="forward">Next</a>
  </div>
  '''
  data: ->
    store: window.availability-store
  computed:
    date: -> @store.attention-day.format 'ddd, MMM D'
  methods:
    forward: -> @store.bump-attention-day 1
    backward: -> @store.bump-attention-day -1

Vue.component 'app' do
  template: '''
  <div style="display: flex; flex-wrap: nowrap;">
    <div>
      <date-scrubber></date-scrubber>
      <floor-list></floor-list>
      <room-list></room-list>
    </div>
    <div style="min-width: 200px;"><floorplan></floorplan></div>
    <calendar></calendar>
  </div>
  '''


$ ->
  @app = new Vue el: '#myapp'
