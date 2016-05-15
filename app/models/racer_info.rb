class RacerInfo
  include Mongoid::Document

  field :fn, as: :first_name, type: String
  field :ln, as: :last_name, type: String
  field :g, as: :gender, type: String
  field :yr, as: :birth_year, type: Integer
  field :res, as: :residence, type: Address
  field :racer_id, as: :_id
  field :_id, default:->{ racer_id }

  embedded_in :parent, polymorphic: true

  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :gender
  validates_presence_of :birth_year
  validates :gender, :inclusion => { :in => ['M', 'F'] }
  validates :birth_year, :numericality => { :less_than => Date.current.year }

  # The following code block demonstrates creating a getter and setter method 
  # for each of our Address properties within the RacerInfo class – making sure 
  # to apply the single field change to an entire instance of Account that
  # was created from the current state and re-assigned as a whole object.
  #   - city and state are defined in an array that is passed in as the action to perform
  #   - two methods are created; (action) and (action)= to act as the getter and setter for that property
  #   - both perform nil checks on the residence
  #   - the getter pulls the desired field from the embedded custom type
  #   - the setter applies the value to the desired field and re-assigns the state for the the entire custom type  
  ["city", "state"].each do |action|
    define_method("#{action}") do
      self.residence ? self.residence.send("#{action}") : nil
    end
    define_method("#{action}=") do |name|
      object=self.residence ||= Address.new
      object.send("#{action}=", name)
      self.residence=object
    end
  end  

end
