require 'rubygems'
require 'nokogiri'
require 'json'
require 'open-uri'

# =============== Methods for json extraction ===============

def seeding_trails
  locations = []

  filepath = File.join(__dir__, 'data/parsed_trails.json')
  serialized_locations = File.read(filepath)
  trails_json = JSON.parse(serialized_locations)

  trails_json.each do |trail_array|
    trail_hash = trail_array[1]
    locations << trail_hash
  end
  return locations
end

def seeding_checkpoints
  filepath = File.join(__dir__, 'data/parsed_location.json')
  serialized_checkpoint = File.read(filepath)
  checkpoints_json = JSON.parse(serialized_checkpoint)

  Trail.all.each_with_index do |trail, index|
    if index > 3
      key = "##{index - 3}"
      previous_checkpoint = nil
      checkpoint = Checkpoint.new(
      name: checkpoints_json[key]["name"],
      longitude: checkpoints_json[key]["longitude"],
      latitude: checkpoints_json[key]["latitude"],
      elevation: 0
      )
      checkpoint.previous_checkpoint = previous_checkpoint unless previous_checkpoint.nil?
      checkpoint.trail = trail
      checkpoint.save
    end
  end
end

def seeding_items
  filepath = File.join(__dir__, 'data/checklist.json')
  serialized_locations = File.read(filepath)
  items_json = JSON.parse(serialized_locations)
  filepath_meals = File.join(__dir__, 'data/meals.json')
  serialized_meals = File.read(filepath_meals)
  meals_json = JSON.parse(serialized_meals)

  items_json["checklist"].each do |category, category_item|
    category_item.each do |required, required_array|
      required_array.each do |item_name|
        item = Item.create!(name: item_name)
        item.tag_list.add(category)
        case required
        when "cold_weather" || "snow_weather"
          item.tag_list.add("required")
          item.tag_list.add(required)
        else
          item.tag_list.add(required)
        end

        if item_name === "Backpacking tent"
          item.tag_list.add("camping")
        elsif ["Mug/Cup", "Dish/Bowl", "Utensils"].include?(item_name)
          item.tag_list.add("utensils")
        end
        item.save
      end
    end
  end

  meals_json["meals"].each do |meal_key, meal_hash|
    meal_hash.each do |meal_item_key, meal_item_arr|
      meal_item_arr.each do |item_name|
        item = Item.create!(name: item_name)
        item.tag_list.add("required")
        item.tag_list.add("food")
        item.tag_list.add(meal_key)
        item.tag_list.add(meal_item_key)
        item.save
      end
    end
  end
end

def seeding_checklists
  trips = Trip.all
  items = Item.tagged_with(["food"], exclude: true)

  items_breakfast = Item.tagged_with("breakfast")
  items_breakfast_uncooked = Item.tagged_with("breakfast").tagged_with(["cooking"], exclude:true)

  items_lunch_dinner = Item.tagged_with("lunch_dinner") # if cooking = true
  items_lunch_dinner_uncooked = Item.tagged_with("lunch_dinner").tagged_with(["cooking"], exclude:true) # if cooking = false

  items_no_camping_no_cooking = Item.tagged_with(["camping, food, kitchen_tools"], exclude: true)
  items_utensils = Item.tagged_with(["utensils"])
  items_no_camping = Item.tagged_with(["camping, food"], exclude: true) # if camping = false
  items_no_cooking = Item.tagged_with(["kitchen_tools, food"], exclude: true) # if camping = false

  trips.each do |trip|
    trip_days = (trip.end_date - trip.start_date).to_i + 1
    #items

    # camping false #cooking true
    if !trip.camping && trip.cooking
      # add items except for camping, food tags
      items_no_camping.each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
      # cooking
      items_breakfast.sample(trip_days).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
      items_lunch_dinner.sample(trip_days * 2).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
    # camping false #cooking false
    elsif !trip.camping && !trip.cooking
      # add items except for camping, food, kitchen_tools tags
      items_no_camping_no_cooking.each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end

      # add utensils
      items_utensils.each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end

      # not cooking
      items_breakfast_uncooked.sample(trip_days).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
      items_lunch_dinner_uncooked.sample(trip_days * 2).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
    # camping true #cooking false
    elsif trip.camping && !trip.cooking
      items_no_cooking.each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end

      # add utensils
      items_utensils.each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end

      # not cooking
      items_breakfast_uncooked.sample(trip_days).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
      items_lunch_dinner_uncooked.sample(trip_days * 2).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
    # camping true #cooking true
    else
      items.each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
      # cooking
      items_breakfast.sample(trip_days).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
      items_lunch_dinner.sample(trip_days * 2).each do |item|
        Checklist.create(trip: trip, checked: false, item: item)
      end
    end
  end
end

def seeding_emergency_contacts
  EmergencyContact.create!(name: "Bheemuscles", email: "bhee_muscles@hero.com", phone_no:"+65 9999 9999", user: User.first )
  puts "First emergency contact created ☑"
  EmergencyContact.create!(name: "Bestie Ng", email: "bestie_2010@friendster.com", phone_no:"+65 9109 9678", user: User.first )
  puts "Second emergency contact created ☑"
end

def seeding_users
  # Creating a static user instance
  puts "Creating our first user.. 🧔"
  User.create!(
      first_name: "Geetha",
      last_name: "Bheema",
      email: "geebee@gmail.com",
      password: "password",
      active: "true"
    )
  puts "Standard user Geetha created! ✅"

  puts "Creating a temp user... 😬"
  User.create!(
      first_name: "Alicia",
      last_name: "Keys",
      email: "placeholder@email.com",
      password: "placeholder",
      active: "false"
    )
  puts "Temp user created! ✅"

  puts "Creating an admin user... 🤓"
  User.create!(
      first_name: "Administrator",
      last_name: "Offgrid",
      email: "admin@offgrid.com",
      password: ENV['ADMIN_ACCOUNT_PASSWORD'],
      active: "true",
      admin: true
    )
  puts "Admin user created! ✅"
end

def seeding_manual_routes
  puts "Creating the manual trails 🛤"
  puts "Routeburn Track 🥾"
  routeburn = Trail.create!(
    id: 0,
    name: "Routeburn Track",
    description: "Routeburn Track is a 32.2 kilometer heavily trafficked point-to-point trail located near Glenorchy, Otago, New Zealand that features a lake and is rated as difficult. The trail offers a number of activity options and is best used from October until May.",
    location: "Fiordland National Park",
    time_needed: "4D3N",
    route_distance: "33km",
    photo_url: "https://photos.alltrails.com/eyJidWNrZXQiOiJhc3NldHMuYWxsdHJhaWxzLmNvbSIsImtleSI6InVwbG9hZHMvcGhvdG8vaW1hZ2UvMTQ2NDIxODcvN2RjZGJhMTk0ZDI2Yjg4YTM0YWFlMmExZWRkZGQ1NTMuanBnIiwiZWRpdHMiOnsidG9Gb3JtYXQiOiJqcGVnIiwicmVzaXplIjp7IndpZHRoIjoyMDQ4LCJoZWlnaHQiOjIwNDgsImZpdCI6Imluc2lkZSJ9LCJyb3RhdGUiOm51bGwsImpwZWciOnsidHJlbGxpc1F1YW50aXNhdGlvbiI6dHJ1ZSwib3ZlcnNob290RGVyaW5naW5nIjp0cnVlLCJvcHRpbWlzZVNjYW5zIjp0cnVlLCJxdWFudGlzYXRpb25UYWJsZSI6M319fQ=="
  )

  puts "Creating checkpoints for Routeburn 🚩"
  routeburn_checks = {
    point_0: ["Routeburn Shelter", -44.718018, 168.274247, 483],
    point_1: ["Routeburn Flats Hut & Camp", -44.725466, 168.214794, 705],
    point_2: ["Routeburn Falls Hut", -44.725819, 168.198392, 993],
    point_3: ["Lake Mackenzie Hut", -44.767611, 168.173198, 909],
    point_4: ["The Divide Shelter & Car Park", -44.824875, 168.117152, 528],
  }

  previous_checkpoint = nil
  routeburn_checks.each do |key, value|
    checkpoint = Checkpoint.new(
      name: value[0],
      latitude: value[1],
      longitude: value[2],
      elevation: value[3]
    )

    checkpoint.previous_checkpoint = previous_checkpoint unless previous_checkpoint.nil?

    checkpoint.trail = routeburn
    checkpoint.save!

    previous_checkpoint = checkpoint
  end

  puts "Routeburn done ✅"

  puts "Mount Ollivier Summit via Mueller Hut 🥾"
  mueller = Trail.create!(
    id: 1,
    name: "Mount Ollivier Summit via Xenicus Peak",
    description: "Mount Ollivier Summit via Mueller Hut Route cuts through Xenicus Peak. It is a 11.6 kilometer moderately trafficked out and back trail located near Mount Cook Village, Canterbury, New Zealand that features a great forest setting and is only recommended for very experienced adventurers. The trail offers a number of activity options.",
    location: "Aoraki/Mount Cook National Park",
    time_needed: "3D2N",
    route_distance: "11.6km",
    photo_url: "https://cdn-assets.alltrails.com/uploads/photo/image/20352078/extra_large_0feaf75812e5dd34de16aa52e348c7e0.jpg"
  )

  puts "Creating checkpoints for Mueller 🚩"
  mueller_checks = {
    point_0: ["Kea Point Trailhead", -43.71875, 170.0926, 773],
    point_1: ["Mueller Hut", -43.721064, 170.064537, 1805],
    point_2: ["Mount Ollivier", -43.725504, 170.064457, 1883],
    point_3: ["Kea Point Trailhead", -43.71875, 170.0926, 773],
  }

  previous_checkpoint = nil
  mueller_checks.each do |key, value|
    checkpoint = Checkpoint.new(
      name: value[0],
      latitude: value[1],
      longitude: value[2],
      elevation: value[3]
    )

    checkpoint.previous_checkpoint = previous_checkpoint unless previous_checkpoint.nil?

    checkpoint.trail = mueller
    checkpoint.save!

    previous_checkpoint = checkpoint
  end

  puts "Mueller done ✅"

  puts "Sunrise Track 🌄"
  sunrise = Trail.create!(
    id: 3,
    name: "Sunrise Track",
    description: "This well-graded track is a great overnight tramp for families with children and new trampers - it passes through changing forest types to the open tops, with great views of the Hawke's Bay plains and excellent sunrises from the hut.",
    location: "Ruahine Forest Park",
    time_needed: "2D1N",
    route_distance: "10.4km",
    photo_url: "https://photos.alltrails.com/eyJidWNrZXQiOiJhc3NldHMuYWxsdHJhaWxzLmNvbSIsImtleSI6InVwbG9hZHMvcGhvdG8vaW1hZ2UvMjkwNTYzMDUvOTZhOTQ2NTkzNTFjNTFhMzdlMDViYTVjZGFlOTA1ZjEuanBnIiwiZWRpdHMiOnsidG9Gb3JtYXQiOiJqcGVnIiwicmVzaXplIjp7IndpZHRoIjoyMDQ4LCJoZWlnaHQiOjIwNDgsImZpdCI6Imluc2lkZSJ9LCJyb3RhdGUiOm51bGwsImpwZWciOnsidHJlbGxpc1F1YW50aXNhdGlvbiI6dHJ1ZSwib3ZlcnNob290RGVyaW5naW5nIjp0cnVlLCJvcHRpbWlzZVNjYW5zIjp0cnVlLCJxdWFudGlzYXRpb25UYWJsZSI6M319fQ=="
  )

  puts "Creating checkpoints for Sunrise Track 🚩"
  sunrise_checks = {
    point_0: ["North Block Road End", -39.795726884963834, 176.2023274641028, 604],
    point_1: ["Sunrise Hut", -39.78629590330388, 176.16816685221022, 1280],
    point_2: ["North Block Road End", -39.795726884963834, 176.2023274641028, 604],
  }

  previous_checkpoint = nil
  sunrise_checks.each do |key, value|
    checkpoint = Checkpoint.new(
      name: value[0],
      latitude: value[1],
      longitude: value[2],
      elevation: value[3]
    )

    checkpoint.previous_checkpoint = previous_checkpoint unless previous_checkpoint.nil?

    checkpoint.trail = sunrise
    checkpoint.save!

    previous_checkpoint = checkpoint
  end

  puts "Sunrise done ✅"

  puts "Mount Somers Track 🐑"
  somers = Trail.create!(
    id: 4,
    name: "Mount Somers Track: Woolshed Creek Hut",
    description: "The Mount Somers Track provides a number of options, including for kids, for an overnight tramp with impressive rock formations, historic mines and stunning views. It links the popular Pinnacles and Woolshed Creek huts.",
    location: "Hakatere Conservation Park",
    time_needed: "2D1N",
    route_distance: "22.8km",
    photo_url: "https://cdn-assets.alltrails.com/uploads/photo/image/24464687/extra_large_c02bd0b3164f6140694e08084ae1dfde.jpg"
  )

  puts "Creating checkpoints for Mount Somers Track 🚩"
  somers_checks = {
    point_0: ["Sharplin Falls Car Park", -43.62450371804988, 171.41831992902678, 580],
    point_1: ["Woolshed Creek Hut", -43.598776043809785, 171.32613777532666, 828],
    point_2: ["Sharplin Falls Car Park", -43.62450371804988, 171.41831992902678, 580],
  }

  previous_checkpoint = nil
  somers_checks.each do |key, value|
    checkpoint = Checkpoint.new(
      name: value[0],
      latitude: value[1],
      longitude: value[2],
      elevation: value[3]
    )

    checkpoint.previous_checkpoint = previous_checkpoint unless previous_checkpoint.nil?

    checkpoint.trail = somers
    checkpoint.save!

    previous_checkpoint = checkpoint
  end

  puts "Mount Somers Track done ✅"

  puts "End of manual trails 👌"
end

def seeding_trail_difficulty
  difficulty = %w[easy medium hard]
  Trail.all.each do |trail|
    trail.tag_list.add(difficulty.sample)
    trail.save
  end
end
# =============== End of methods section ===============

# Start of seeding
puts "Seeding database.."

# Removing old data
puts "Deleting existing database.. 💣"
Trail.destroy_all
User.destroy_all
Item.destroy_all
EmergencyContact.destroy_all
puts "Deleted!"


trail_seed = seeding_trails
# Creating instance models here
puts "creating trails.."
trail_seed.each do |trail|
  Trail.create!(
    name: trail["name"],
    description: trail["description"],
    location: trail["location"],
    time_needed: trail["time_needed"],
    route_distance: trail["route_distance"],
    photo_url: trail["photo"]
  )
end
puts "adding checkpoints to trails"
seeding_checkpoints
puts "Trails created!"
# =============== end of static data ===============
seeding_manual_routes
# =============== static data ===============
seeding_trail_difficulty
puts "Tagging trail difficulty"

seeding_users
seeding_emergency_contacts

# extracting from json files
puts "extracting information from json files.."

puts "infomation extracted!"

# Creating the first trip for first user
puts "Booking a trip for our first user 📑"
status = ["upcoming", "ongoing", "return"]
trip = Trip.create!(
  trail: Trail.last,
  user: User.first,
  start_date: Date.today,
  end_date: Date.today + 3,
  no_of_people: 1,
  status: status[0],
  cooking: false,
  camping: true,
  last_seen_photo: "",
  last_photo: DateTime.now + 8.hours,
  emergency_contact: EmergencyContact.first,
  release_date_time: DateTime.new(Date.today.year, Date.today.month, Date.today.day + 2, 9)
)
file = URI.open('https://source.unsplash.com/400x400/?person')
puts "Attaching photo to trip"
trip.photo.attach(io: file, filename: "#{trip.trail.name}_photo.jpg", content_type: "image/jpg")

puts "Trip has been booked!"

# method for Item seeding

puts "********START: Seeding items*************"
seeding_items
puts "********END: Seeding items***************"

puts "********START: Seeding checklist************"
seeding_checklists
puts "********END: Seeding checklist*************"

# End of seeding

puts "Seeding complete!"
