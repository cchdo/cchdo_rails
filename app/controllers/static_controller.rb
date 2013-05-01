class StaticController < ApplicationController

  def index
    basepath = params[:path] || ''
    basepath = basepath.join('/') if basepath.kind_of?(Array)
    basepath = 'static/' + basepath

    render_cached(basepath) && return if template_exists?(basepath)
    path = basepath + 'index.rhtml'
    render_cached(path) && return if template_exists?(path)
    path = basepath + 'index.html.erb'
    render_cached(path) && return if template_exists?(path)

    raise ::ActionController::RoutingError, "Recognition failed for #{request.path.inspect}"
  end

  private

    NO_CACHE = ['static/about/website']

    # It's deprecated in Rails 2.3
    unless ActionController::Base.private_instance_methods.include? 'template_exists?'
      def template_exists?(path)
        self.view_paths.find_template(path, response.template.template_format)
      rescue ActionView::MissingTemplate
        false
      end
    end

    def render_cached(path)
      #if NO_CACHE.include? path
      render :template => path
      #else
      #   key = path.gsub('/', '-')
      #   unless content = read_fragment(key)
      #      content = render_to_string :template => path, :layout => false
      #      write_fragment(key, content)
      #   end
      #   render :text => content, :layout => true
      #end
    end
end
