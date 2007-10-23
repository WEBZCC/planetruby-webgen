require 'uri'

module Tag

  # Changes the path of file. This is very useful for templates. For example, you normally include a
  # stylesheet in a template. If you specify the filename of the stylesheet directly, the reference
  # to the stylesheet in the output file of a page file that is not in the same directory as the template
  # would be invalid.
  #
  # By using the +relocatable+ tag you ensure that the path stays valid.
  #
  # Tag parameter: the name of the file which should be relocated
  class Relocatable < DefaultTag

    def process_tag( tag, body, context )
      uri_string = param( 'path' )
      result = ''
      unless uri_string.nil?
        begin
          uri = URI.parse( uri_string )
          if uri.absolute?
            result = uri_string
          else
            result = resolve_path( uri, context.ref_node, context.node )
          end
          log(:error) { "Could not resolve path '#{uri_string}' in <#{context.ref_node.node_info[:src]}>" } if result.empty?
        rescue URI::InvalidURIError => e
          log(:error) { "Error while parsing path for tag relocatable in <#{context.ref_node.node__info[:src]}>: #{e.message}" }
        end
      end
      result
    end

    #######
    private
    #######

    def query_fragment( uri )
      (uri.query.nil? ? '' : '?'+ uri.query ) + (uri.fragment.nil? ? '' : '#' + uri.fragment)
    end

    def resolve_path( uri, ref_node, node )
      dest_node = @plugin_manager['Core/CacheManager'].node_for_path( ref_node, uri.path, node['lang'] )
      if !dest_node.nil? && !uri.fragment.nil? && param( 'resolveFragment' )
        dest_node = dest_node.resolve_node( '#' + uri.fragment )
      end
      if dest_node.nil?
        ''
      else
        result = (dest_node.is_fragment? ? dest_node.parent : dest_node)
        node.route_to( dest_node.is_fragment? ? dest_node.parent : dest_node ) + query_fragment( uri )
      end
    end

  end

end
