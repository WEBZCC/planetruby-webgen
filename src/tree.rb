require 'composite'
require 'configuration'

class Node
	
	include Composite

	attr_reader   :title
	attr_reader   :url
	attr_reader   :srcName
	attr_reader   :virtual
	attr_accessor :content
	
	def initialize(title, url, srcName, virtual)
		init_composite

		@title = title
		@url = url
		@srcName = srcName
		@virtual = virtual
	end

end

class DirectoryNode < Node
	
	attr_reader :templateFile

	def initialize(title, dir, parentTemplateFile)
		cfg = Configuration.instance

		if !File.exists?(File.join(cfg.srcDirectory, dir, cfg.directoryIndexFile))
			raise ThaumaturgeException.new("create an #{cfg.directoryIndexFile} in that directory"), 
				"directory index file does not exist for #{dir == '' ? 'root directory' : dir}", caller
		end

		urlName = (dir+'/'+cfg.directoryIndexFile).gsub(/\.xml$/, '.html')
		super(title, urlName, dir+'/'+cfg.directoryIndexFile, true)
		
		@templateFile = File.join(cfg.srcDirectory, dir, cfg.templateFile)
		if !File.exists?(@templateFile)
			if dir == '' # dir is root directory
				raise ThaumaturgeException.new("create an #{cfg.templateFile} in the root directory"),
					"directory index file in root directory not found", caller
			end
			@templateFile = parentTemplateFile
		end
	end
	
end
