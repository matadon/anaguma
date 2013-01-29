require "spec_helper"
require "kusuri/active_record/fragment"

describe Kusuri::ActiveRecord::Fragment do
    # it just needs to know about types for columns so that it can handle
    # type coercion, and we can set that from the compiler by passing a type
    # hash.
    #
    # we aren't going to handle joins just yet, not this time around.  next
    # version, and that'll probably be more for the compiler anyway
    # (although we'll need to figure out how to track down column names and
    # types across joins, maybe...)
    #
    # what about aggregates and functions? these get handled at the compiler
    # level, not by us.
end
