require '../db/big_seeds'
require '../db/small_seeds'

if Rails.env.production?
  BigSeeds.new.run
else
  SmallSeeds.new.run
end
