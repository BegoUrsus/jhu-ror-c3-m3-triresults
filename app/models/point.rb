class Point
	attr_accessor :longitude, :latitude

  def initialize(lng, lat)
    @longitude = lng
    @latitude = lat
  end

  # creates a DB-form of the instance
	# 	marshals the state of the instance into MongoDB format as a Ruby hash
	# 	produce a MongoDB format consistent with the following:
	# 			{:type=>"Point", :coordinates=>[(longitude), (latitude)]}
	def mongoize
		return {:type => "Point", :coordinates => [@longitude, @latitude]}
	end

	# returns the state marshalled into MongoDB format as a Ruby hash
  # takes in all forms of the object and produces a DB-friendly form
	def self.mongoize object
		case object
		when nil then
			nil
		when Hash then
			if object[:type] #in GeoJSON Point format
				Point.new(object[:coordinates][0], object[:coordinates][1]).mongoize
			else       #in legacy format
				Point.new(object[:lng], object[:lat]).mongoize
			end
		when Point then
			object.mongoize
		end
	end

	#creates an instance of the class from the DB-form of the data
	# returns an instance of the class (if appropriate)
	def self.demongoize object
    case object
    when nil
      nil
    when Hash then 
      Point.new(object[:coordinates][0], object[:coordinates][1])
    when Point then
    	object
    end
	end

	# functionally behaves the same as the mongoize class method
  # used by criteria to convert object to DB-friendly form
  def self.evolve(object)
    case object
    when nil then
    	nil
    when Point then 
    	object.mongoize
    else 
    	object
    end
  end



end