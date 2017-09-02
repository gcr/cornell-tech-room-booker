// Generated by LiveScript 1.4.0
(function(){
  var parseEventsToMoments, momentToMidnightMinutes, makeCurrentTimeRange, AvailabilityStore, availabilityStore, out$ = typeof exports != 'undefined' && exports || this;
  parseEventsToMoments = function(events){
    var whichDay, resultEvents, i$, len$, ref$, start, end, busy, thisMorning, thisEvening, endIntersection, startIntersection;
    whichDay = moment();
    whichDay = moment().subtract(1, 'day');
    resultEvents = [];
    for (i$ = 0, len$ = events.length; i$ < len$; ++i$) {
      ref$ = events[i$], start = ref$.start, end = ref$.end, busy = ref$.busy;
      thisMorning = moment(whichDay).startOf('day');
      thisEvening = moment(whichDay).endOf('day');
      start = moment.utc(start);
      end = moment.utc(end);
      endIntersection = moment.min(end, thisEvening);
      startIntersection = moment.max(start, thisMorning);
      if (endIntersection.diff(startIntersection) > 0) {
        resultEvents.push({
          start: startIntersection,
          end: endIntersection
        });
      }
    }
    return resultEvents;
  };
  out$.momentToMidnightMinutes = momentToMidnightMinutes = function(point){
    return point.diff(moment(point).local().startOf('day')) / 1000.0 / 60.0;
  };
  makeCurrentTimeRange = function(){
    var nowMinutes, startMinutes;
    nowMinutes = momentToMidnightMinutes(moment());
    startMinutes = Math.floor(nowMinutes / 30.0) * 30.0;
    return {
      start: startMinutes,
      end: startMinutes + 30
    };
  };
  out$.AvailabilityStore = AvailabilityStore = (function(){
    AvailabilityStore.displayName = 'AvailabilityStore';
    var prototype = AvailabilityStore.prototype, constructor = AvailabilityStore;
    function AvailabilityStore(){
      this.attentionRooms = [];
      this.attentionRoomStatus = {};
      this.selectedRoom = null;
      this.attentionFloor = null;
      this.currentTimeRange = makeCurrentTimeRange();
      this.nowMinute = momentToMidnightMinutes(moment());
      this.cachedAvailability = {};
      this.queryDebounceRooms = {};
      this.queryServerPromise = null;
    }
    prototype.highlightHalfHourBlock = function(hour){
      this.currentTimeRange.start = hour * 60;
      this.currentTimeRange.end = hour * 60 + 30;
      return this.updateAttentionRoomStatus();
    };
    prototype.loadAvailability = function(roomNetid){
      if (!(roomNetid in this.cachedAvailability)) {
        this.cachedAvailability[roomNetid] = {
          loaded: false,
          events: [],
          errorMessage: ""
        };
        this.queryDebounceRooms[roomNetid] = true;
        this.queryServerForAvailabilities();
      }
      return this.cachedAvailability[roomNetid];
    };
    prototype.promiseAvailability = function(roomNetid){};
    prototype.queryServerForAvailabilities = function(){
      var this$ = this;
      if (this.queryServerPromise) {
        return this.queryServerPromise;
      } else {
        return this.queryServerPromise = new Promise(function(resolve, reject){
          return setTimeout(function(){
            var room, _;
            return $.ajax({
              dataType: 'json',
              method: 'POST',
              url: '/availability',
              data: {
                rooms: (function(){
                  var ref$, results$ = [];
                  for (room in ref$ = this.queryDebounceRooms) {
                    _ = ref$[room];
                    results$.push(room);
                  }
                  return results$;
                }.call(this$))
              },
              error: function(err){
                this$.queryDebounceRooms = {};
                this$.queryServerPromise = null;
                return reject(err);
              },
              success: function(arg$){
                var ok, err, roomId, ref$, errorMessage, events, oldEvents, i$, len$, ev;
                ok = arg$.ok, err = arg$.err;
                this$.queryDebounceRooms = {};
                this$.queryServerPromise = null;
                if (err) {
                  return reject(err);
                } else {
                  for (roomId in ok) {
                    ref$ = ok[roomId], errorMessage = ref$.errorMessage, events = ref$.events;
                    this$.cachedAvailability[roomId].errorMessage = errorMessage;
                    this$.cachedAvailability[roomId].loaded = true;
                    oldEvents = this$.cachedAvailability[roomId].events;
                    oldEvents.splice(0);
                    for (i$ = 0, len$ = (ref$ = parseEventsToMoments(events)).length; i$ < len$; ++i$) {
                      ev = ref$[i$];
                      oldEvents.push(ev);
                    }
                    this$.updateAttentionRoomStatus();
                  }
                  return resolve();
                }
              }
            });
          }, 100);
        });
      }
    };
    prototype.timeSelected = function(startMin, endMin){
      return Math.max(this.currentTimeRange.start, startMin) < Math.min(this.currentTimeRange.end, endMin);
    };
    prototype.eventSelected = function(arg$){
      var start, end;
      start = arg$.start, end = arg$.end;
      return this.timeSelected(momentToMidnightMinutes(start), momentToMidnightMinutes(end));
    };
    prototype.updateAttentionRoomStatus = function(){
      var i$, ref$, len$, roomid, lresult$, availability, j$, ref1$, len1$, event, results$ = [];
      for (i$ = 0, len$ = (ref$ = this.attentionRooms).length; i$ < len$; ++i$) {
        roomid = ref$[i$];
        lresult$ = [];
        Vue['delete'](this.attentionRoomStatus, roomid);
        availability = this.loadAvailability(roomid);
        if (!availability.loaded) {
          lresult$.push(Vue.set(this.attentionRoomStatus, roomid, "Loading"));
        } else {
          Vue.set(this.attentionRoomStatus, roomid, "Available");
          for (j$ = 0, len1$ = (ref1$ = availability.events).length; j$ < len1$; ++j$) {
            event = ref1$[j$];
            if (this.eventSelected(event)) {
              lresult$.push(Vue.set(this.attentionRoomStatus, roomid, "Booked"));
            }
          }
        }
        results$.push(lresult$);
      }
      return results$;
    };
    prototype.setAttentionRooms = function(newRoomIds){
      var i$, len$, id;
      this.attentionRooms.splice(0);
      for (i$ = 0, len$ = newRoomIds.length; i$ < len$; ++i$) {
        id = newRoomIds[i$];
        this.attentionRooms.push(id);
      }
      return this.updateAttentionRoomStatus();
    };
    prototype.setAttentionFloor = function(newFloorName){
      return this.attentionFloor = newFloorName;
    };
    return AvailabilityStore;
  }());
  out$.availabilityStore = availabilityStore = new AvailabilityStore();
}).call(this);
