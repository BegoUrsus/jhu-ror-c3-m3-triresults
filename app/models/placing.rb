class Placing
	attr_accessor :name, :place 

	def initialize (name, place)
		@name = name
		@place = place
	end

	# creates a DB-form of the instance
	# 	marshals the state of the instance into MongoDB format as a Ruby hash
	# 	produce a MongoDB format consistent with the following:
	# 			{:name=>"(category name)" :place=>"(ordinal placing)"}
	def mongoize
		return {:name => @name, :place => @place}
	end

	# returns the state marshalled into MongoDB format as a Ruby hash
	# takes in all forms of the object and produces a DB-friendly form
	def self.mongoize object
		case object
		when nil then
			nil
		when Hash then
			Placing.new(object[:name], object[:place]).mongoize
		when Placing then
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
			Placing.new(object[:name], object[:place])
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
  	when Placing then 
  		object.mongoize
  	else 
  		object
  	end
  end

end