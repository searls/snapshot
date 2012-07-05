# class CreateElectionSnapshots < ActiveRecord::Migration
#   def up
#     create_table :election_snapshots do |t|
#       t.text :election
#       t.string :office
#       t.integer :year
#     end
#   end
#
#   def down
#     drop_table :election_snapshots
#   end
# end


class Election
  attr_reader :office, :year, :probability, :winner, :loser

  def initialize(options=nil)
    return unless options

    @expensive_thing_you_do_not_want_to_save = "OHNOES"

    @office = options[:office]
    @year = options[:year]
    @winner = options[:winner]
  end

  def tally
    @probability = 43.39
  end
end

class LocalElection < Election
  def tally
    @probability = 68.93
  end
end

class ElectionSnapshot < Snapshot
  takes_snapshots_of Election
  can_be_identified_by :office, :year

  before_snapshot :tally

  required_attributes :probability, :winner
  optional_attributes :loser
  transient_instance_variables :expensive_thing_you_do_not_want_to_save
end
