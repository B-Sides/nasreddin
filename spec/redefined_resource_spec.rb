require 'spec_helper'

describe 'A Resource loaded twice' do
  it 'reuses an anonymous parent class' do
    load File.expand_path('../fixtures/redefined.rb', __FILE__)

    -> { load File.expand_path('../fixtures/redefined.rb', __FILE__) }.should_not raise_exception
  end
end
