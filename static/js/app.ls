export CORNELL_TECH_RED = "\#b31b1b"

export BACKGROUND_LOADING = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAYAAADgzO9IAAAAIUlEQVQYV2PcLC393/fpU0YGNIAhAJMnTgLZWOJ0INsPADIQCAdlTP30AAAAAElFTkSuQmCC"

export BACKGROUND_LOADING = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAKElEQVQYV2NkQAObpaX/MyKLgQR8nz5lhAvCBECKwILIAmBBdAGQIABEwxHu9sr/MwAAAABJRU5ErkJggg=="

Vue.component 'floor-list' do
  template: '''
  <ul class="floor-list">
    <li v-for="floor in floorlist">
      <button :class="{floor: true, active: isActive(floor)}" @click="selectFloor(floor)">
        {{floor.name}}
        &nbsp;
        <i v-if="isActive(floor)" class="fa fa-check"></i>
      </button>
    </li>
  </ul>
  '''
  data: ->
    floorlist: FLOOR_LIST
    current-floor: null
    store: availability-store
  methods:
    is-active: (floor) -> @current-floor == floor.name
    selectFloor: (floor) ->
      @current-floor = floor.name
      all-room-ids = [r.id for r in floor.rooms]
      @store.set-attention-floor floor.name
      @store.set-attention-rooms all-room-ids

Vue.component 'room-list' do
  template: '''
  <div class="room-list">
    <div class="app-header">
      <h1 class="wide">{{description}}</h1>
    </div>
    <ul>
      <li :class="classfor(roomid)" v-for="roomid in attentionRooms">
        <a href="#" @click="click(roomid)">
          {{roomName[roomid]}}
          &nbsp;
          <i v-if="isSelected(roomid)" class="fa fa-check"></i>
        </a>
      </li>
      <span v-if="attentionRooms.length == 0">
        No rooms to show. Select a location at the top left.
      </span>
    </ul>
  </div>
  '''
  data: ->
    attentionRooms: availability-store.attentionRooms
    roomName: ROOMID_TO_NAME
    status: availability-store.attentionRoomStatus
  methods:
    click: (roomid) -> availability-store.select-room roomid
    is-selected: (roomid) -> availability-store.selected-room == roomid
    classfor: (roomid) ->
      @status[roomid] + (if @is-selected roomid then " selected" else "")
  computed:
    description: ->
      n-available = [r for r in @attentionRooms when @status[r]=="Available"].length
      n-loading = [r for r in @attentionRooms when @status[r]=="Loading"].length
      if @attentionRooms.length < 2
        "Room list"
      else if n-loading > 0 and n-available == 0
        "Room list"
      else if n-available == 0
        "No rooms free"
      else
        "#{n-available} rooms free"

Vue.component 'date-scrubber' do
  template: '''
  <div class="date-scrubber app-header">
    <h1>
    {{date}}
    <button class="btn" @click="backward">
      <i class="fa fa-chevron-left"></i>
    </button>
    <button class="btn" @click="forward">
      <i class="fa fa-chevron-right"></i>
    </button>
    </h1>
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
  <div class="app">
    <div class="app-pane">
      <date-scrubber></date-scrubber>
      <floor-list></floor-list>
      <room-list></room-list>
    </div>
    <div class="map app-pane">
      <div class="app-header">
        <h1 class="wide">Map</h1>
      </div>
      <floorplan></floorplan>
    </div>
    <div class="calendar" style="flex: 1 0 35em;">
      <calendar></calendar>
    </div>
  </div>
  '''


$ ->
  @app = new Vue el: '#myapp'
