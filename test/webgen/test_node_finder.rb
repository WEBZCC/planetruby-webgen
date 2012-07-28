# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/node_finder'

class TestNodeFinder < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    @config = {}
    setup_website(@config)
    @nf = Webgen::NodeFinder.new(@website)
  end

  def test_add_filter_module
    m = Module.new
    m.send(:define_method, :filter_something) { :value }

    assert_raises(ArgumentError) { @nf.add_filter_module(m, :name => 'unknown_method') }
    assert_raises(NoMethodError) { @nf.filter_something }
    @nf.add_filter_module(m, :something => 'filter_something')
    assert_equal('filter_something', @nf.instance_eval { @mapping[:something] })
    assert_equal(:value, @nf.filter_something)
  end

  def test_find
    setup_default_nodes(@website.tree)
    tree = @website.tree

    check = lambda do |correct, result|
      assert_equal(correct.collect {|n| tree[n]}, result, "Failure at #{caller[0]}")
    end
    @config['node_finder.option_sets'] = {'simple' => {:alcn => '', :unknown => ''}}

    assert_raises(ArgumentError) { @nf.find(['hallo'], tree['/']) }

    # test using configured search options
    check.call(%w[/], @nf.find('simple', tree['/']))
    check.call(%w[/file.en.html], @nf.find('simple', tree['/file.en.html']))

    # test limit, offset, flatten, levels
    check.call(%w[/file.en.html /other.en.html],
               @nf.find({:alcn => '/**/*.en.html', :limit => 2}, tree['/']))
    check.call(%w[/dir2/index.en.html],
               @nf.find({:alcn => '/**/*.en.html', :limit => 2, :offset => 2}, tree['/']))

    assert_equal([[tree['/file.en.html'], [tree['/file.en.html#frag']]],
                  [tree['/file.de.html'], [tree['/file.de.html#frag']]],
                  tree['/other.html'],
                  tree['/other.en.html'],
                  tree['/german.de.html'],
                  [tree['/dir/'], [tree['/dir/subfile.html'], tree['/dir/dir/']]],
                  [tree['/dir2/'], [tree['/dir2/index.en.html'], tree['/dir2/index.de.html']]]
                 ],
                 @nf.find({:levels => [1,2]}, tree['/']))

    # test sort methods
    check.call(%w[/file.en.html /file.de.html /dir/dir/file.html /german.de.html /dir2/index.de.html
                  /dir2/index.en.html /other.html /other.en.html /dir/subfile.html],
               @nf.find({:alcn => '/**/*.html', :flatten => true, :sort => true}, tree['/']))
    check.call(%w[/dir/dir/file.html /file.de.html /file.en.html /german.de.html /dir2/index.de.html /dir2/index.en.html
                  /other.html /other.en.html /dir/subfile.html],
               @nf.find({:alcn => '/**/*.html', :name => 'test', :flatten => true, :sort => 'title'}, tree['/']))
    assert_equal([[tree['/file.en.html'], [[tree['/file.en.html#frag'], [tree['/file.en.html#nested']]]]],
                  [tree['/file.de.html'], [tree['/file.de.html#frag']]],
                  [tree['/dir/'], [[tree['/dir/dir/'], [tree['/dir/dir/file.html']]],
                                   [tree['/dir/subfile.html'], [tree['/dir/subfile.html#frag']]]]],
                  [tree['/dir2/'], [tree['/dir2/index.de.html'], tree['/dir2/index.en.html']]],
                  tree['/german.de.html'], tree['/other.html'], tree['/other.en.html'],
                 ],
                 @nf.find({:levels => [1,3], :sort => true}, tree['/']))

    # test filter: meta info keys/values
    check.call(['/file.en.html#frag', '/file.de.html#frag', '/dir/subfile.html#frag'],
               @nf.find({'title' => 'frag', :flatten => true}, tree['/']))

    # test filter: alcn
    check.call(%w[/],
               @nf.find({:alcn => '/'}, tree['/']))
    check.call(%w[/ /dir/subfile.html /dir/subfile.html#frag /dir/dir/],
               @nf.find({:alcn => ['/', '*'], :flatten => true}, tree['/dir/']))

    # test filter: and/or
    check.call(%w[/file.en.html /file.de.html /other.html /other.en.html /german.de.html ],
               @nf.find({:alcn => '/**/*.html', :and => {:alcn => '*.html'}, :flatten => true}, tree['/']))
    check.call(%w[/file.en.html /file.de.html /other.html /other.en.html /german.de.html /dir/subfile.html /dir/dir/file.html
                  /dir2/index.en.html /dir2/index.de.html /],
               @nf.find({:alcn => '/**/*.html', :or => 'simple', :flatten => true}, tree['/']))

    # test filter: levels
    check.call(%w[/],
               @nf.find({:levels => [0, 0], :flatten => true}, tree['/dir/']))
    check.call(%w[/file.en.html#nested /dir/subfile.html#frag /dir/dir/file.html],
               @nf.find({:levels => [3,3], :flatten => true}, tree['/dir/']))
    check.call(%w[/ /file.en.html /file.de.html /other.html /other.en.html /german.de.html /dir/ /dir2/],
               @nf.find({:levels => [0,1], :flatten => true}, tree['/dir/']))

    # test filter: langs
    check.call(%w[/file.en.html /other.en.html /dir2/index.en.html],
               @nf.find({:lang => 'en', :flatten => true}, tree['/dir/']))
    check.call(%w[/file.en.html /file.de.html /other.en.html /german.de.html /dir2/index.en.html /dir2/index.de.html],
               @nf.find({:lang => ['en', 'de'], :flatten => true}, tree['/dir/']))
    check.call(%w[/file.en.html /other.en.html /dir2/index.en.html],
               @nf.find({:lang => :node, :flatten => true}, tree['/file.en.html']))
  end

end
