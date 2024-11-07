# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

require 'rails_helper'

describe Kpi::SupervisorToCaseworkerRatio do
  include FormAndFieldHelper
  include SunspotHelper

  let(:group1) { 'group1' }
  let(:group2) { 'group2' }
  let(:group3) { 'group3' }

  before :each do
    clean_data
  end

  after :each do
    clean_data
  end
end
