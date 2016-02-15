#! /usr/local/bin/ruby

# Utility script for rebuilding the ferret index in production land

# Set up all the railsy stuff
Rails.env = "production"
require File.dirname(__FILE__) + '/../config/environment'

Product.rebuild_index
Category.rebuild_index
