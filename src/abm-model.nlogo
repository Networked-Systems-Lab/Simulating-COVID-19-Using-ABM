extensions [ gis ]

globals [
  districts-dataset
  stateboundary-dataset
  boundary-dataset
  district-list
  airport-dataset
  checkposts-dataset
  trip-number
  curr-post
  dabolim
  flight-i
  flight-it
  ;constants
  percent-alight ;percentage of people getting down from the train
  percent-board ;percentage of people entering train
  recovery-time ;minimum time a person will take to recover
  death-chances ;analogous to mortality rate
  recovery-chances ;analogous to recovery rate
  infection-chances ;how probable it is to get infected by an infected person in radius x
  rec-infection-chances
  affected-recovery-chances
  exposure-chances ;; chances of contact
  incubation-period ; assuming they are asymtomatic during this period and cant infect others
  num-susceptible ; susceptible = not infected and not exposed yet
  num-infected ;infected
  num-exposed ;exposed to disease by an infected person, but not infected yet
  num-recovered
  num-deceased

  north_goa_vf
  south_goa_vf

  north_goa_loc
  south_goa_loc

  day
  hour

  post_bus
  time_bus
  checkposts
  i_o_bus
  north_goa_posts_bus
  south_goa_posts_bus

  flight-number
  curr-flight
  start-time_air
  end-time_air
  i_o_air

  train-number
  konkan-train
  konkan-dataset
  train-it
  rev-train-it
  station-it
  rev-station-it
  n
  start-time_train
  end-time_train
  curr-station
  to-get-in
  to-get-down

]

;not travelling currently
breed [persons person]
persons-own [
  district
  last-travel
  state
]

;travelling currently
breed [passengers passenger]
passengers-own [
  trip
  flight
  train
  station
  ptype
]

turtles-own [
  susceptible?
  infected?
  exposed?
  recovered?
  deceased?
  sick-time
  incubation ;after exposure, how much time has passed in hours
]

to setup
  ca
  ask patches [set pcolor white]
  setup-constants
  setup-gis
  setup-count
  create-pop
  random-seed seed
  reset-ticks
end

to setup-constants
  set recovery-time 240
  set death-chances 5
  set incubation-period 96
  set infection-chances 70
  set recovery-chances 80
  set affected-recovery-chances 99
  set percent-board 0.5
  set percent-alight 0.5
end

to setup-count
  set num-exposed 0
  set num-infected 0
  set num-recovered 0
  set num-deceased 0
end


to setup-gis
  gis:load-coordinate-system "../maps/Districts.prj"
  set districts-dataset gis:load-dataset "../maps/Districts.shp"
  set stateboundary-dataset gis:load-dataset "../maps/State_Boundary.shp"
  set airport-dataset gis:load-dataset "../maps/Airports.shp"
  set checkposts-dataset gis:load-dataset "../maps/CheckPost.shp"
  set konkan-dataset gis:load-dataset "../maps/Konkan_Railways.shp"
  gis:set-world-envelope (gis:envelope-union-of
    (gis:envelope-of districts-dataset)
    (gis:envelope-of stateboundary-dataset)
  (gis:envelope-of airport-dataset)
    )

  gis:set-drawing-color black
  gis:draw stateboundary-dataset 1

end

;creating population
to create-pop

  set north_goa_vf gis:find-one-feature districts-dataset "DISTRICT" "North Goa"
  set south_goa_vf gis:find-one-feature districts-dataset "DISTRICT" "South Goa"

  set north_goa_loc gis:location-of gis:centroid-of north_goa_vf
  set south_goa_loc gis:location-of gis:centroid-of south_goa_vf

  create-persons (read-from-string gis:property-value north_goa_vf "population") * 0.001
  [
         setxy item 0 north_goa_loc + (random-float 0.5)  item 1 north_goa_loc + (random-float 0.5)
         set color gray
         set shape "circle"
         set size 0.2
         set susceptible? true
         set exposed? false
         set infected? false
         set district north_goa_vf
         set sick-time 0
         set incubation 0
         set recovered? false
         set deceased? false
         set last-travel 0
  ]

  create-persons (read-from-string gis:property-value south_goa_vf "population") * 0.001
  [
         setxy item 0 south_goa_loc + (random-float 0.5)  item 1 south_goa_loc + (random-float 0.5)
         set color gray
         set shape "circle"
         set size 0.2
         set susceptible? true
         set exposed? false
         set infected? false
         set district south_goa_vf
         set sick-time 0
         set incubation 0
         set recovered? false
         set deceased? false
         set last-travel 0
  ]

  set num-susceptible count turtles with [susceptible?]
  ask n-of initial-infected turtles with [not infected? and gis:property-value district "DISTRICT" = "South Goa"]
  [
    set susceptible? false
    set infected? true
    set num-infected (num-infected + 1)
    set num-susceptible (num-susceptible - 1)
    set color red + 2
  ]

  ask n-of initial-infected turtles with [not infected? and gis:property-value district "DISTRICT" = "North Goa"]
  [
    set susceptible? false
    set infected? true
    set num-infected (num-infected + 1)
    set num-susceptible (num-susceptible - 1)
    set color red + 2
  ]

  repeat 10
  [
    ask persons [move-in-district]
  ]

end

to simulate-road-travel
  set trip-number 0
  while [trip-number < max-trips]
  [
    set curr-post (item (item trip-number post_bus) checkposts)
    if hour = (item trip-number time_bus)
    [
      ifelse (item trip-number i_o_bus) = 0 [exit-goa] [enter-goa]
    ]

    set trip-number (trip-number + 1)
  ]

end

to simulate-air-travel
  set flight-number 0
  while [flight-number < max-flights]
  [
      ;getting in the flight at start time
     if hour = (item flight-number start-time_air)
     [
         ifelse (item flight-number i_o_air) = 0 [get-in-outgoing-flight] [get-in-incoming-flight]
     ]

     ;travel in each hour
     if hour >= (item flight-number start-time_air) and hour <= (item flight-number end-time_air)
     [
         travel-flight
     ]

     ;getting out of flight at end time
     if hour = (item flight-number end-time_air)
     [
          ifelse (item flight-number i_o_air) = 0 [get-down-outgoing-flight] [get-down-incoming-flight]
     ]
     set flight-number (flight-number + 1)
 ]
end

to simulate-train-travel
  set train-number 0
  while [train-number < max-trains]
  [
    set station-it (item train-number train-it)
    set curr-station item station-it konkan-train

    ;start of train journey, passengers get in
    if hour = (item train-number start-time_train)
    [
      set to-get-in num-passengers-train
      get-in
      set station-it station-it + 1
      travel-train
    ]

    ;every hour in the journey, people travel (locations change) and they get in and out
    if hour > (item train-number start-time_train) and hour < (item train-number end-time_train)
    [
      set station-it station-it + 1
      travel-train
      exchange
    ]

    ;end of journey, everyone on train gets down
    if hour = (item train-number end-time_train)
    [
      travel-train
      set to-get-down count passengers with [train = train-number]
      get-down
      set station-it 0
    ]

    set train-it replace-item train-number train-it station-it
    set train-number (train-number + 1)
  ]


  ;reverse trains
  let rev-train-number 12
  while [rev-train-number < max-trains + 12]
  [
    set train-number rev-train-number
    set rev-station-it (item (rev-train-number - 12) rev-train-it)
    set curr-station item rev-station-it konkan-train

    ;start of train journey, passengers get in
    if hour = (item (rev-train-number - 12) start-time_train)
    [
      set to-get-in num-passengers-train
      get-in
      set rev-station-it rev-station-it - 1
      travel-train
    ]

    ;every hour in the journey, people travel (locations change) and they get in and out
    if hour > (item (rev-train-number - 12) start-time_train) and hour < (item (rev-train-number - 12) end-time_train)
    [
      set rev-station-it rev-station-it - 1
      travel-train
      exchange
    ]

    ;end of journey, everyone on train gets down
    if hour = (item (rev-train-number - 12) end-time_train)
    [
      travel-train
      set to-get-down count passengers with [train = rev-train-number]

      get-down
      set rev-station-it length konkan-train - 1
    ]

    set rev-train-it replace-item (rev-train-number - 12) rev-train-it rev-station-it
    set rev-train-number (rev-train-number + 1)
  ]



end



to go

  random-seed seed
  set checkposts []
  foreach gis:feature-list-of checkposts-dataset
  [
    vf -> set checkposts insert-item 0 checkposts vf
  ]

  set curr-post item 0 checkposts
  set day 1

  set time_bus n-values max-trips [i -> remainder (i + 1) 23]
  set post_bus n-values max-trips [i -> remainder (remainder (i) 6) 4]

  set i_o_bus shuffle n-values max-trips [i -> floor( (2 * i) / max-trips)] ; 0 - outgoing, 1 - incoming

  set north_goa_posts_bus n-values 4 [i -> gis:contains? north_goa_vf (item i checkposts)]
  set south_goa_posts_bus n-values 4 [i -> gis:contains? south_goa_vf (item i checkposts)]

  set dabolim gis:find-one-feature airport-dataset "NAME" "Dabolim"
  set curr-flight dabolim

  set start-time_air n-values max-flights [i -> remainder (i + 1) 23]
  set end-time_air n-values max-flights [i -> (item i start-time_air) + 1 ]
  set i_o_air shuffle n-values max-flights [i -> floor( (2 * i) / max-flights)] ; 0 - outgoing, 1 - incoming

  set konkan-train gis:feature-list-of konkan-dataset

  set station-it 0
  set rev-station-it length konkan-train
  set n length konkan-train

  set start-time_train [1 2 3 4 5 6 7 8 9 10 11 12 ]
  set end-time_train [9 10 11 12 13 14 15 16 17 18 19 20]

;  print post
;  print i_o
;  print north_goa_posts
;  print south_goa_posts

  while [day <= 28]
  [
      set hour 0
      set train-it [0 0 0 0 0 0 0 0 0 0 0 0]
      set rev-train-it n-values 12 [i -> length konkan-train - 1]

      while [hour < 24]
      [

        if road-travel
        [
          simulate-road-travel
        ]
        if air-travel
        [
          simulate-air-travel
        ]
        if train-travel
        [
          simulate-train-travel
        ]


        ifelse rf = 0
        [
          go-home
        ]
        [
          go-home
          mingle
        ]

        infect
        recover

        tick
        set hour hour + 1

    ]
    set day day + 1
  ]

  stop

end


to recover

  if count turtles with [infected?] != 0
  [
    ask persons with [infected?]
    [
      set sick-time (sick-time + 1)
      if sick-time > recovery-time
      [
        ifelse recovered?
        [
          ifelse random 100 < affected-recovery-chances
          [
            set infected? false
            set recovered? true
            set susceptible? false
            set num-recovered (num-recovered + 1)
            set sick-time 0
          ]
          [
            if random 100 < death-chances
            [
              set num-deceased (num-deceased + 1)
              die
            ]
          ]
        ]
        [
          ifelse random 100 < recovery-chances
          [
            set infected? false
            set recovered? true
            set susceptible? false
            set num-recovered (num-recovered + 1)
            set sick-time 0
          ]
          [
            if random 100 < death-chances
            [
              set num-deceased (num-deceased + 1)
              die
            ]
          ]
        ]
      ]
    ]
  ]

end



to mingle

  if count persons with [infected?] != 0
  [
    ask persons with [infected?] [expose-people]
  ]
  ask persons [ move ]

end

to go-home

  if count persons with [infected?] != 0
  [
    ask persons with [infected?] [expose-people]
  ]

  if count (persons with [last-travel > 0]) > 0
  [
    ask persons with [last-travel > 0]
    [
      car-travel
      set last-travel (last-travel - 1)
    ]
  ]

end

to expose-people

  if count (persons-here with [ not infected? and not recovered?] in-radius 0.001) != 0
  [
     ask (persons-here with [ not infected? and not recovered?] in-radius 0.001)
     [
        if susceptible? = true
        [
          set exposed? true
          set susceptible? false
          set num-exposed (num-exposed + 1)
          set num-susceptible (num-susceptible - 1)
        ]
      ]
  ]

end


to infect

  ask turtles with [exposed? = true]
  [
     set incubation (incubation + 1)
     if incubation > incubation-period
     [
       ifelse random 100 < infection-chances
       [
         set infected? true
         set exposed? false
         set num-infected (num-infected + 1)
         set num-exposed (num-exposed - 1)
       ]
       [
         set exposed? false
         set susceptible? true
         set num-exposed (num-exposed - 1)
         set num-susceptible (num-susceptible + 1)
       ]
     ]
   ]

end


to car-travel
  ;make sure not going out of borders of district/india

  repeat 5
  [
    let dist district
    let x-cor xcor
    let y-cor ycor
    right random 360 forward (random 20) * 0.03
    let condition1 gis:contains? north_goa_vf person who
    let condition2 gis:contains? south_goa_vf person who
    if (not condition1) and (not condition2)
    [
      set xcor x-cor
      set ycor y-cor
    ]

    if condition1
    [
      set district north_goa_vf
    ]
    if condition2
    [
      set district south_goa_vf
    ]
  ]

end

to move

  let x-cor xcor
  let y-cor ycor
  right random 360 forward (random 20) * 0.03
  let condition1 gis:contains? north_goa_vf person who
  let condition2 gis:contains? south_goa_vf person who

  if (not condition1) and (not condition2)
  [
    set xcor x-cor
    set ycor y-cor
  ]

  if condition1 [set district north_goa_vf]
  if condition2 [set district south_goa_vf]

end

to move-in-district

  let dist district
  let x-cor xcor
  let y-cor ycor

  left random 360 forward (random 20) * 0.03
  let condition1 gis:contains? north_goa_vf person who
  let condition2 gis:contains? south_goa_vf person who

  if dist = north_goa_vf and not condition1
  [
    set xcor x-cor
    set ycor y-cor
  ]

  if dist = south_goa_vf and not condition2
  [
    set xcor x-cor
    set ycor y-cor
  ]
end

to travel-bus

  let p passengers with [trip = trip-number]
  if count p with [infected?]  != 0
  [
    ask p with [infected?][expose-passengers]
  ]

  if count p != 0
  [
    ask p
    [
      let loc gis:location-of gis:centroid-of curr-post
      let x-cor (item 0 loc)
      let y-cor (item 1 loc)
      setxy x-cor y-cor
    ]
  ]

end

to travel-flight

  let p passengers with [flight = flight-number]
  if count p with [infected?]  != 0
  [
    ask p with [infected?][expose-passengers]
  ]

  if count p != 0
  [
    ask p
    [
      let loc gis:location-of gis:centroid-of curr-flight
      let x-cor (item 0 loc)
      let y-cor (item 1 loc)
      setxy x-cor y-cor
    ]
  ]

end

to travel-train

  let p passengers with [train = train-number]
  if count p with [infected?]  != 0
  [
    ask p with [infected?][expose-passengers]
  ]

  if count p != 0
  [
    ask p
    [
      let loc gis:location-of gis:centroid-of curr-station
      let x-cor (item 0 loc)
      let y-cor (item 1 loc)
      setxy x-cor y-cor
    ]
  ]

end

to expose-passengers
   if count (passengers-here with [ not infected? ] in-radius 0.01) != 0
   [
     ask (passengers-here with [ not infected? ] in-radius 0.01)
     [
       if susceptible? = true
        [
          set exposed? true
          set susceptible? false
          set num-exposed (num-exposed + 1)
          set num-susceptible (num-susceptible - 1)
        ]
    ]
  ]
end

to exit-goa
  set to-get-in num-passengers-bus
  ask n-of to-get-in persons [die]
end

to enter-goa

  let x-cor n-values num-passengers-bus [i -> 0]
  let y-cor n-values num-passengers-bus [i -> 0]
  let colorp n-values num-passengers-bus [i -> gray]
  let inf n-values num-passengers-bus [i -> false]
  let suc n-values num-passengers-bus [i -> false]
  let expo n-values num-passengers-bus [i -> false]
  let vacc n-values num-passengers-bus [i -> false]
  let rec n-values num-passengers-bus [i -> false]
  let sit n-values num-passengers-bus [i -> 0]
  let incu n-values num-passengers-bus [i -> 0]

  let loc gis:location-of gis:centroid-of curr-post
  set x-cor (item 0 loc)
  set y-cor (item 1 loc)

  let iter 0
  ask n-of num-passengers-bus persons
  [
    set colorp replace-item iter colorp color
    set inf replace-item iter inf infected?
    set suc replace-item iter suc susceptible?
    set expo replace-item iter expo exposed?
    set rec replace-item iter rec recovered?
    set sit replace-item iter sit sick-time
    set incu replace-item iter incu incubation
    set iter iter + 1
  ]

  set iter 0
  create-persons num-passengers-bus
  [
    set color (item iter colorp)
    set shape "circle"
    set infected? (item iter inf)
    set susceptible? (item iter suc)
    set exposed? (item iter expo)
    set recovered? (item iter rec)
    set sick-time (item iter sit)
    set incubation(item iter incu)

    let loc1 gis:location-of gis:centroid-of curr-post
    set x-cor (item 0 loc1)
    set y-cor (item 1 loc1)
    setxy x-cor y-cor
    set size 0.2
    let condition1 gis:contains? north_goa_vf person who
    let condition2 gis:contains? south_goa_vf person who
    if condition1 [set district north_goa_vf]
    if condition2 [set district south_goa_vf]
    set last-travel 4
    set iter iter + 1
  ]

end

to get-in-outgoing-flight

  let x-cor n-values num-passengers-flight [i -> 0]
  let y-cor n-values num-passengers-flight [i -> 0]
  let colorp n-values num-passengers-flight [i -> gray]
  let inf n-values num-passengers-flight [i -> false]
  let suc n-values num-passengers-flight [i -> false]
  let expo n-values num-passengers-flight [i -> false]
  let vacc n-values num-passengers-flight [i -> false]
  let rec n-values num-passengers-flight [i -> false]
  let sit n-values num-passengers-flight [i -> 0]
  let incu n-values num-passengers-flight [i -> 0]


  let loc gis:location-of gis:centroid-of curr-flight
  set x-cor (item 0 loc)
  set y-cor (item 1 loc)

  let iter 0
  ask n-of num-passengers-flight persons
  [
      set colorp replace-item iter colorp color
      set inf replace-item iter inf infected?
      set suc replace-item iter suc susceptible?
      set expo replace-item iter expo exposed?
      set rec replace-item iter rec recovered?
      set sit replace-item iter sit sick-time
      set incu replace-item iter incu incubation
      set iter iter + 1
      die
  ]

  set iter 0
  create-passengers num-passengers-flight
  [
    set color (item iter colorp)
    set shape "circle"
    set infected? (item iter inf)
    set susceptible? (item iter suc)
    set exposed? (item iter expo)
    set recovered? (item iter rec)
    set sick-time (item iter sit)
    set incubation(item iter incu)

    let loc1 gis:location-of gis:centroid-of curr-flight
    set x-cor (item 0 loc1)
    set y-cor (item 1 loc1)
    setxy x-cor y-cor
    set size 0.2
    set flight flight-number

    set ptype "flight"

    set trip -1
    set train -1
    set station -1

    set iter iter + 1
  ]

end

to get-down-outgoing-flight
  ask passengers with [flight = flight-number] [ die ]
end

to get-in-incoming-flight

  let x-cor n-values num-passengers-flight [i -> 0]
  let y-cor n-values num-passengers-flight [i -> 0]
  let colorp n-values num-passengers-flight [i -> gray]
  let inf n-values num-passengers-flight [i -> false]
  let suc n-values num-passengers-flight [i -> false]
  let expo n-values num-passengers-flight [i -> false]
  let vacc n-values num-passengers-flight [i -> false]
  let rec n-values num-passengers-flight [i -> false]
  let sit n-values num-passengers-flight [i -> 0]
  let incu n-values num-passengers-flight [i -> 0]

  let loc gis:location-of gis:centroid-of curr-flight
  set x-cor (item 0 loc)
  set y-cor (item 1 loc)

  let iter 0
  ask n-of num-passengers-flight persons
  [
    set colorp replace-item iter colorp color
    set inf replace-item iter inf infected?
    set suc replace-item iter suc susceptible?
    set expo replace-item iter expo exposed?
    set rec replace-item iter rec recovered?
    set sit replace-item iter sit sick-time
    set incu replace-item iter incu incubation
    set iter iter + 1
  ]

  set iter 0
  create-passengers num-passengers-flight
  [
    set color (item iter colorp)
    set shape "circle"
    set infected? (item iter inf)
    set susceptible? (item iter suc)
    set exposed? (item iter expo)
    set recovered? (item iter rec)
    set sick-time (item iter sit)
    set incubation(item iter incu)

    let loc1 gis:location-of gis:centroid-of curr-flight
    set x-cor (item 0 loc1)
    set y-cor (item 1 loc1)
    setxy x-cor y-cor
    set size 0.2
    set flight flight-number
    set ptype "flight"

    set trip -1
    set train -1
    set station -1


    set iter iter + 1
  ]

end

to get-down-incoming-flight

  let x-cor n-values num-passengers-flight [i -> 0]
  let y-cor n-values num-passengers-flight [i -> 0]
  let colorp n-values num-passengers-flight [i -> gray]
  let inf n-values num-passengers-flight [i -> false]
  let suc n-values num-passengers-flight [i -> false]
  let expo n-values num-passengers-flight [i -> false]
  let vacc n-values num-passengers-flight [i -> false]
  let rec n-values num-passengers-flight [i -> false]
  let sit n-values num-passengers-flight [i -> 0]
  let incu n-values num-passengers-flight [i -> 0]


  let loc gis:location-of gis:centroid-of curr-flight
  set x-cor (item 0 loc)
  set y-cor (item 1 loc)


  let iter 0
  ask passengers with [flight = flight-number]
  [
    set colorp replace-item iter colorp color
    set inf replace-item iter inf infected?
    set suc replace-item iter suc susceptible?
    set expo replace-item iter expo exposed?
    set rec replace-item iter rec recovered?
    set sit replace-item iter sit sick-time
    set incu replace-item iter incu incubation
    set iter iter + 1
    die
  ]

  set iter 0
  create-persons num-passengers-flight
  [
    set color (item iter colorp)
    set shape "circle"
    set infected? (item iter inf)
    set susceptible? (item iter suc)
    set exposed? (item iter expo)
    set recovered? (item iter rec)
    set sick-time (item iter sit)
    set incubation(item iter incu)
    let loc1 gis:location-of gis:centroid-of curr-flight
    set x-cor (item 0 loc1)
    set y-cor (item 1 loc1)
    setxy x-cor y-cor
    set size 0.2
    set district south_goa_vf
    set last-travel 5
    set iter iter + 1
  ]

end


to exchange
  let x count passengers with [train = train-number]
  set to-get-in round (percent-board * x)
  get-in
  set to-get-down round (percent-alight * x)
  get-down
end

to get-down

  let x-cor 0
  let y-cor 0

  let colorp n-values to-get-down [i -> gray]
  let inf n-values to-get-down [i -> false]
  let suc n-values to-get-down [i -> false]
  let expo n-values to-get-down [i -> false]
  let rec n-values to-get-down [i -> false]
  let sit n-values to-get-down [i -> 0]
  let incu n-values to-get-down [i -> 0]


  let loc gis:location-of gis:centroid-of curr-station
  set x-cor (item 0 loc)
  set y-cor (item 1 loc)

  let iter 0
  ask n-of to-get-down passengers with [train = train-number]
  [
      set colorp replace-item iter colorp color
      set inf replace-item iter inf infected?
      set suc replace-item iter suc susceptible?
      set expo replace-item iter expo exposed?
      set rec replace-item iter rec recovered?
      set sit replace-item iter sit sick-time
      set incu replace-item iter incu incubation
      set iter iter + 1
      die
  ]

  set iter 0
  create-persons to-get-down
  [
    set color (item iter colorp)
    set shape "circle"
    set infected? (item iter inf)
    set susceptible? (item iter suc)
    set exposed? (item iter expo)
    set recovered? (item iter rec)
    set sick-time (item iter sit)
    set incubation(item iter incu)

    let loc1 gis:location-of gis:centroid-of curr-station
    set x-cor (item 0 loc1)
    set y-cor (item 1 loc1)
    setxy x-cor y-cor
    if gis:contains? north_goa_vf person who [set district north_goa_vf]
    if gis:contains? south_goa_vf person who [set district south_goa_vf]
    set last-travel 2
    set size 0.2
    set iter iter + 1
  ]
end

to get-in

  let x-cor 0
  let y-cor 0

  let loc gis:location-of gis:centroid-of curr-station
  set x-cor (item 0 loc)
  set y-cor (item 1 loc)

  let x persons


  let radius 0

  ask patch x-cor y-cor
  [
    set radius neighbors
  ]

  set to-get-in min (list count persons-on radius to-get-in)


  let colorp n-values to-get-in [i -> gray]
  let inf n-values to-get-in [i -> false]
  let suc n-values to-get-in [i -> false]
  let expo n-values to-get-in [i -> false]
  let rec n-values to-get-in [i -> false]
  let sit n-values to-get-in [i -> 0]
  let incu n-values to-get-in [i -> 0]

  let iter 0
  ask n-of to-get-in persons-on radius
  [
      set colorp replace-item iter colorp color
      set inf replace-item iter inf infected?
      set suc replace-item iter suc susceptible?
      set expo replace-item iter expo exposed?
      set rec replace-item iter rec recovered?
      set sit replace-item iter sit sick-time
      set incu replace-item iter incu incubation
      set iter iter + 1
      die
  ]

  set iter 0
  create-passengers to-get-in
  [
    set color (item iter colorp)
    set shape "circle"
    set infected? (item iter inf)
    set susceptible? (item iter suc)
    set exposed? (item iter expo)
    set recovered? (item iter rec)
    set sick-time (item iter sit)
    set incubation(item iter incu)

    let loc1 gis:location-of gis:centroid-of curr-station
    set x-cor (item 0 loc1)
    set y-cor (item 1 loc1)
    setxy x-cor y-cor
    set station curr-station
    set size 0.2
    set train train-number
    set ptype "train"
    set trip -1
    set flight -1

    set iter iter + 1
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
24
616
431
-1
-1
12.061
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
477
446
541
479
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
549
446
615
479
Go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
625
333
753
378
Confirmed Infections
num-infected
17
1
11

MONITOR
211
439
301
484
Total population
count turtles
17
1
11

MONITOR
308
439
425
484
Passengers
count passengers
17
1
11

PLOT
632
81
905
255
Total Goa Cases
Ticks
Number of People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"infected" 1.0 0 -2139308 true "" "plot count turtles with [infected?]"
"deceased" 1.0 0 -9276814 true "" "plot num-deceased"
"recovered" 1.0 0 -14835848 true "" "plot num-recovered"
"confirmed" 1.0 0 -13345367 true "" "plot num-infected"

PLOT
910
81
1148
256
North Goa Cases
Ticks
Number of People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"active" 1.0 0 -2139308 true "" "plot count persons with [infected? and gis:property-value district \"District\" = \"North Goa\"]"
"recovered" 1.0 0 -14835848 true "" "plot count persons with [recovered? and gis:property-value district \"DISTRICT\" = \"North Goa\"]"

PLOT
1154
82
1397
257
South Goa Cases
Ticks
Number of People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"active" 1.0 0 -2139308 true "" "plot count persons with [infected? and gis:property-value district \"District\" = \"South Goa\"]"
"recovered" 1.0 0 -14835848 true "" "plot count persons with [recovered? and gis:property-value district \"DISTRICT\" = \"South Goa\"]"

SLIDER
822
36
994
69
max-trips
max-trips
10
100
60.0
10
1
NIL
HORIZONTAL

SLIDER
640
36
812
69
initial-infected
initial-infected
0
10
10.0
1
1
NIL
HORIZONTAL

MONITOR
624
280
699
325
Susceptible
count turtles with [susceptible?]
17
1
11

MONITOR
769
280
829
325
Infected
count turtles with [infected?]
17
1
11

MONITOR
704
280
764
325
Exposed
count turtles with [exposed?]
17
1
11

MONITOR
834
280
898
325
Recovered
count turtles with [recovered?]
17
1
11

MONITOR
903
280
960
325
Dead
num-deceased
17
1
11

MONITOR
625
385
710
430
Infected Pax
count passengers with [infected?]
17
1
11

SLIDER
1196
301
1368
334
rf
rf
0
1
0.0
1
1
NIL
HORIZONTAL

MONITOR
853
372
1141
417
NIL
count persons with [district = north_goa_vf]
17
1
11

MONITOR
856
425
1145
470
NIL
count persons with [district = south_goa_vf]
17
1
11

INPUTBOX
13
25
162
85
seed
7.0
1
0
Number

SLIDER
1005
37
1177
70
max-flights
max-flights
10
100
50.0
10
1
NIL
HORIZONTAL

SLIDER
1192
37
1364
70
max-trains
max-trains
1
12
6.0
1
1
NIL
HORIZONTAL

SWITCH
707
525
821
558
air-travel
air-travel
1
1
-1000

SWITCH
830
525
957
558
road-travel
road-travel
1
1
-1000

SWITCH
966
525
1093
558
train-travel
train-travel
0
1
-1000

MONITOR
211
494
327
539
Flight Passengers
count passengers with [ptype = \"flight\"]
17
1
11

MONITOR
337
494
447
539
Train Passengers
count passengers with [ptype = \"train\"]
17
1
11

SLIDER
1184
349
1379
382
num-passengers-train
num-passengers-train
0
200
10.0
10
1
NIL
HORIZONTAL

SLIDER
1184
389
1382
422
num-passengers-flight
num-passengers-flight
0
20
9.0
1
1
NIL
HORIZONTAL

SLIDER
1184
430
1373
463
num-passengers-bus
num-passengers-bus
0
20
5.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>export-all-plots (word "CSV/" max-trains "results.csv")</final>
    <enumeratedValueSet variable="initial-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-trains">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>export-plot "Plot" (word date-and-time "plot.csv")</final>
    <enumeratedValueSet variable="initial-infected">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-vaccinated">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="initial-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-vaccinated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multipletrains" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-plot "Total Goa Cases" (word max-trains "TotalGoaCases.csv")
export-plot "North Goa Cases" (word max-trains "NorthGoaCases.csv")
export-plot "South Goa Cases" (word max-trains "SouthGoaCases.csv")</final>
    <enumeratedValueSet variable="max-trains">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="5trains" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-all-plots (word "CSV/" max-trains "results.csv")</final>
    <enumeratedValueSet variable="max-trains">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final_exp" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-plot "Total Goa Cases" (word max-trains "TotalGoaCases.csv")
export-plot "North Goa Cases" (word max-trains "NorthGoaCases.csv")
export-plot "South Goa Cases" (word max-trains "SouthGoaCases.csv")</final>
    <enumeratedValueSet variable="max-trains">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infected">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="time_exp" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-plot "Total Goa Cases" (word max-flights "TotalGoaCases_Efficient.csv")</final>
    <enumeratedValueSet variable="initial-infected">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flights">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rest_free" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-plot "Total Goa Cases" (word rf "TotalGoaCasesBus.csv")</final>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="initial-infected">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-trips">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-passengers">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rf">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
