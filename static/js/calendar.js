// Generated by LiveScript 1.4.0
(function(){
  Vue.component('time-ribbon', {
    template: '<div :style="style"></div>',
    data: function(){
      return {
        store: window.availabilityStore
      };
    },
    computed: {
      shouldShow: function(){
        return moment().isSame(this.store.attentionDay, 'd');
      },
      minute: function(){
        return window.availabilityStore.nowMinute;
      },
      style: function(){
        return {
          position: "absolute",
          height: "6px",
          top: "" + this.minute * 32.0 / 60 + "px",
          width: "100%",
          background: '#b31b1b',
          borderTop: "solid 2px #fff",
          borderBottom: "solid 2px #fff"
        };
      }
    }
  });
  Vue.component('time-square', {
    template: '<div\n  :style="style"\n  @mouseover="mouseover()"\n>{{label}}</div>',
    props: ['hour', 'loaded', 'label'],
    data: function(){
      return {
        store: window.availabilityStore
      };
    },
    methods: {
      mouseover: function(){
        return this.store.highlightHalfHourBlock(this.hour);
      }
    },
    computed: {
      selected: function(){
        return this.store.timeSelected(this.hour * 60, this.hour * 60 + 30);
      },
      style: function(){
        return {
          height: "16px",
          maxHeight: "16px",
          minWidth: "3em",
          background: this.selected
            ? "url(" + BACKGROUND_LOADING + ")"
            : this.loaded
              ? null
              : "url(" + BACKGROUND_LOADING + ")",
          borderTop: this.loaded ? "solid 1px #" + (this.hour % 1 ? 'eee' : '000') : "",
          overflow: "hidden"
        };
      }
    }
  });
  Vue.component('time-square-event', {
    template: '<div :style="style">\n  {{start.local().format(\'h:mm\')}}\n  to\n  {{end.local().format(\'h:mm\')}}\n</div>',
    props: ['start', 'end'],
    computed: {
      startMinutes: function(){
        return momentToMidnightMinutes(this.start);
      },
      endMinutes: function(){
        return momentToMidnightMinutes(this.end);
      },
      style: function(){
        return {
          position: "absolute",
          margin: "0 0.5em",
          backgroundColor: CORNELL_TECH_RED,
          borderRadius: "4px",
          color: "#fff",
          top: "" + this.startMinutes * 32.0 / 60 + "px",
          height: "" + (this.endMinutes - this.startMinutes) * 32.0 / 60 + "px",
          maxHeight: "" + (this.endMinutes - this.startMinutes) * 32.0 / 60 + "px",
          overflow: "hidden"
        };
      }
    }
  });
  Vue.component('show-timeslice', {
    template: '<div>\n   <div class="square" style="position: relative;">\n     <time-square\n       :hour="hour"\n       :loaded="loaded && !errorMessage"\n       :label="renderHour(hour)"\n       v-for="hour in timeslices"\n       ></time-square>\n     <time-ribbon></time-ribbon>\n     <time-square-event\n       v-bind="event"\n       v-for="event in events"></time-square-event>\n   </div>\n</div>',
    props: ['events', 'loaded', 'showHours', 'errorMessage'],
    data: function(){
      return {
        timeslices: [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15, 15.5, 16, 16.5, 17, 17.5, 18, 18.5, 19, 19.5, 20, 20.5, 21, 21.5, 22, 22.5, 23, 23.5]
      };
    },
    methods: {
      renderHour: function(hour){
        if (this.showHours && hour === parseInt(hour)) {
          return moment(hour, "H").format("h");
        }
      }
    },
    computed: {
      nowMinute: function(){
        return momentToMidnightMinutes(moment());
      }
    }
  });
  Vue.component('room-availability-timeslice', {
    template: '<show-timeslice\n  :events="events" :loaded="loaded"\n  ></show-timeslice>',
    props: ['netid'],
    data: function(){
      return {
        store: window.availabilityStore
      };
    },
    computed: {
      events: function(){
        return this.roomData.events;
      },
      loaded: function(){
        return this.roomData.loaded;
      },
      errorMessage: function(){
        return this.roomData.errorMessage;
      },
      roomData: function(){
        return this.store.loadRoomData(this.netid);
      }
    }
  });
  Vue.component('calendar', {
    template: '<div>\n  <div class="app-header">\n    <h1 class="wide">\n      Availability\n      <button class="btn" @click="expand" v-if="showButton">\n        <i v-if="!expanded" class="fa fa-lg fa-eye"></i>\n        <i v-if="expanded" class="fa fa-lg fa-eye-slash"></i>\n        {{expanded? "Hide entire floor" : "Show entire floor"}}\n      </button>\n    </h1>\n  </div>\n  <table>\n    <tr>\n      <th class="open">Room </th>\n      <th v-for="room in roomsToShow">\n          <a :class="{selected: isSelected(room)}"\n              href="#" @click="click(room)">\n            {{roomShortname[room]}}\n            <i v-if="isSelected(room)" class="fa fa-check"></i>\n          </a>\n      </th>\n    </tr>\n    <tr>\n      <td>\n        <show-timeslice showHours="true" loaded="true"></show-timeslice>\n      </td>\n      <td v-for="room in roomsToShow">\n        <room-availability-timeslice :netid="room"></room-availability-timeslice>\n      </td>\n    </tr>\n  </table>\n</div>',
    data: function(){
      return {
        store: availabilityStore,
        roomShortname: ROOMID_TO_SHORTNAME,
        expanded: false
      };
    },
    methods: {
      expand: function(){
        return this.expanded = !this.expanded;
      },
      click: function(room){
        return this.store.selectRoom(room);
      },
      isSelected: function(room){
        return this.store.selectedRoom === room;
      }
    },
    computed: {
      showButton: function(){
        return false;
      },
      selectedRoom: function(){
        return this.store.selectedRoom;
      },
      roomsToShow: function(){
        var expandedRooms;
        expandedRooms = !this.selectedRoom || this.expanded
          ? this.store.attentionRooms
          : [];
        if (this.selectedRoom) {
          return [this.selectedRoom].concat(expandedRooms);
        } else {
          return expandedRooms;
        }
      }
    }
  });
}).call(this);
