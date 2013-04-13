require_relative 'test_helper'

describe 'Post Mortem' do
  include TestDsl

  it 'must enter into post mortem mode' do
    skip('No post morten mode for now')
    enter 'cont'
    debug_file('post_mortem') { Byebug.post_mortem?.must_equal true }
  end

  it 'must stop at the correct line' do
    skip('No post morten mode for now')
    enter 'cont'
    debug_file('post_mortem') { state.line.must_equal 8 }
  end

  it 'must exit from post mortem mode after stepping command' do
    skip('No post morten mode for now')
    enter 'cont', 'break 12', 'cont'
    debug_file('post_mortem') { Byebug.post_mortem?.must_equal false }
  end

  it 'must save the raised exception' do
    skip('No post morten mode for now')
    enter 'cont'
    debug_file('post_mortem') { Byebug.last_exception.must_be_kind_of RuntimeError }
  end
end
