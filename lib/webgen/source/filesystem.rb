module Webgen

  class Source::FileSystem

    class Path < Webgen::Path

      def initialize(path, fs_path)
        super(path)
        @fs_path = fs_path
        WebsiteAccess.website.cache[[:fs_path, @fs_path]] = File.mtime(@fs_path)
      end

      def io(&block)
        File.open(@fs_path, 'r', &block)
      end

      def mount_at(mp)
        self.class.new(File.join(mp, @path), @fs_path)
      end

      def dup
        self.class.new(@path, @fs_path)
      end

      def changed?
        data = WebsiteAccess.website.cache[[:fs_path, @fs_path]]
        !data || File.mtime(@fs_path) > data
      end

    end

    attr_reader :root
    attr_reader :glob

    def initialize(root, glob = '**/*')
      if root =~ /^[a-zA-Z]:|\//
        @root = root
      else
        @root = File.join(WebsiteAccess.website.config['website.dir'], root)
      end
      @glob = glob
    end

    def paths
      @paths ||= Dir.glob(File.join(@root, @glob), File::FNM_DOTMATCH|File::FNM_CASEFOLD).to_set.collect! do |f|
        temp = File.expand_path(f.sub(/^#{@root}\/?/, '/'))
        temp += '/' if File.directory?(f) && temp[-1] != ?/
        path = Path.new(temp, f)
        path
      end
    end

  end

end