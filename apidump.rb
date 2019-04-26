# TODO:
# - Table of Contents

require 'net/http'
require 'json'

module ApiDump
  Version   = "1.0.0.4"
  BuildDate = "190424a"
  CrLf      = 13.chr + 10.chr
  
  class ApiRequest
    attr_accessor :url, :http_method, :output, :headers, :params
    
    def initialize(url, http_method, params = nil, headers = nil)
      @url          = url
      @http_method  = http_method
      @params       = params
      @headers      = headers
    end
    def send_request(uri)
      uri = URI(uri)
      rsp = nil
      
      Net::HTTP.start(uri.host, uri.port) do |http|
        if http_method.downcase == "post"
          req = Net::HTTP::Post.new(uri, @headers)
        else
          req = Net::HTTP::Get.new(uri, @headers)
        end
        
        req.body = @params if @params
        rsp = http.request req
      end
      
      rsp
    end
    def execute
      send_request(@url)
    end
  end
  
  
  class HtmlOutputFormatter
    def initialize(title, version = "", build_date = "")
      @title      = title
      @version    = version
      @build_date = build_date
    end
    def header(extra = "")
      i1 = !@version.empty? ? "Version <b>#{@version}</b>" : ""
      i2 = !@build_date.empty? ? "Build Date <b>#{@build_date}</b>" : ""
      vi = vi = !i1.empty? || !i2.empty? ? "  #{[i1, i2].join(" ")}<br/><br/>" : ""
      
      <<EOS
<html>
<head>
  <title>#{@title}</title>
  
  <style>
    body, td {
      font-family: Verdana;
      font-size: 12px;
    }
    
    h1 {
      font-size: 14px;
    }
    
    h2 {
      font-size: 13px;
    }
    
    h3 {
      font-size: 12px;
    }
    
    h4 {
      font-size: 11px;
    }
    
    h5 {
      font-size: 10px;
    }
    
    h6 {
      font-size: 9px;
    }
    
    pre {
      font-family: Courier New;
      font-size: 12px;
      margin-top: 6px;
      margin-bottom: 0px;
    }
    
    .title {
      width: 100%;
      padding: 4 4 4 4;
      font-size: 12px;
      font-weight: bold;
      background-color: #000000;
      color: #ffffff;
    }
    
    table.api_info {
      cell-spacing: 0;
      cell-padding: 0;
      border-collapse: collapse;
      width: 100%;
      margin-top: 8px;
      table-layout: fixed;
    }
    
    table.api_info td {
      vertical-align: top;
      word-wrap: break-word;
    }
    
    .name {
      font-family: Arial; Tahoma;
      color: #c000c0
    }
    
    .mandatory {
      color: #c00000;
    }
    
    .optional {
      color: #00c000;
    }
  </style>
</head>
<body>
  <a name='#top'>
  <h1>#{@title}</h1>
#{vi}#{extra}
EOS
    end
    def footer(extra = "")
      <<EOS
#{extra}
</body>
</html>
EOS
    end
    def format_feature_begin(feature, request_headers)
      pv = 
        feature.params.values.map do |k,v|
          if v.downcase.index("mandatory")
            cc = " mandatory"
          elsif v.downcase.index("optional")
            cc = " optional"
          else
            cc = ""
          end
          
          "<span class='name#{cc}'>#{k}</span>: #{v}"
        end
      pv = pv.join("<br/>#{CrLf}        ")
      pc = !feature.params.comment.empty? ? "Notes: #{feature.params.comment}" : ""
      
      <<EOS
  <a name = '#{feature.object_id}'>
  <div class="title">
    # #{feature.name}
  </div>
  <table class="api_info">
    <tr>
      <td width="80px">Description</td>
      <td width="10px">:</td>
      <td>
        #{feature.description}
      </td>
    </tr>
    <tr>
      <td>URL</td>
      <td>:</td>
      <td>
        #{feature.url}
      </td>
    </tr>
    <tr>
      <td>Method</td>
      <td>:</td>
      <td>
        #{feature.request_method.upcase}
      </td>
    </tr>
    <tr>
      <td>Headers</td>
      <td>:</td>
      <td>
        #{request_headers}
      </td>
    </tr>
    <tr>
      <td>Parameters</td>
      <td>:</td>
      <td>
        #{[pv, pc].select{|x|!x.empty?}.join("<br/>#{CrLf}        ")}
      </td>
    </tr>
    <tr>
      <td>Examples</td>
      <td>:</td>
      <td>
EOS
    end
    def format_feature_end
      <<EOS
      </td>
    </tr>
  </table>
  <br/>
  <a href='#top'>Back to top</a>
  <br/><br/>
  
EOS
    end
    def format_request(feature, ex_nbr, base_url, params, output = nil, error = nil)
      ex = feature.examples[ex_nbr]
      tt = !ex.title.empty? ? ex.title : "Example: #{ex_nbr}".strip
      
      <<EOS
        <a name='#{ex.object_id}'>
        <h2>#{tt}</h2>
        
        URL:<br/>#{base_url}#{ex.url}<br/>
        <br/>
        
        Parameters:<br/>
        <pre>#{params}</pre>
        <br/>
        
        Output:<br/>
        <pre>#{output ? output : "Error: #{error}"}</pre>
        <br/>
        
        
EOS
    end
    def result(info = "")
      if !info.empty?
        "  <hr/>#{CrLf}#{info}"
      else
        ""
      end
    end
  end
  
  
  class FeatureParam
    attr_accessor :values, :comment
    
    def initialize(options = {})
      @values   = options.fetch(:values, {})
      @comment  = options.fetch(:comment, "")
    end
  end
  
  
  class ApiExample
    attr_accessor :example_id, :title, :comment, :url, :params, :input, :output
    attr_reader   :owner
    
    def initialize(owner = nil, options = {})
      @owner      = owner
      @example_id = options.fetch(:id, :"")
      @title      = options.fetch(:title, "")
      @comment    = options.fetch(:comment, "")
      @url        = options.fetch(:url, "")
      @params     = options.fetch(:params, {})
      @input      = options.fetch(:input, {})
      @output     = options.fetch(:output, {})
    end
  end
  
  
  class ApiFeature
    attr_accessor \
      :name, :description, :request_method, :request_type, :url, :params, :examples
    
    def initialize(options = {})
      @name           = options.fetch(:name, "")
      @description    = options.fetch(:description, "")
      @request_method = options.fetch(:method, "GET")
      @request_type   = options.fetch(:request_type, "JSON")
      @url            = options.fetch(:url, "")
      @params         = FeatureParam.new(options.fetch(:params, {}))
      @examples       = options.fetch(:examples, []).map{|x|ApiExample.new(self, x)}
    end
  end
  
  
  class Specification
    attr_accessor \
      :title, :version, :date, :header, :footer, :base_url, :output_format, :features
    
    def initialize
      @title          = ""
      @version        = ""
      @date           = ""
      @header         = ""
      @footer         = ""
      @base_url       = ""
      @output_format  = ""
      @features       = []
      
      yield(self) if block_given?
    end
    def base_url=(data)
      if !(bu = data.strip).empty?
        bu.chop if bu[-1] == "/"
      end
      
      @base_url = bu
    end
    def features=(data)
      @features = data.map{|f|ApiFeature.new(f)}
    end
    def self.load(spec_file)
      instance_eval File.read(spec_file), spec_file
    end
  end
  
  
  class Generator
    attr_reader :spec, :succ_count, :fail_count
    
    private
    def initialize(spec)
      @spec         = spec
      @output_file  = nil
      @formatter    = nil
      @succ_count   = 0
      @fail_count   = 0
      @results      = {}
    end
    def getterproc(a)
      n = a.split("/")
      
      Proc.new do |x|
        n.map{|x|x.gsub("%slash%", "/")}.inject(x) do |a, b|
          if (!Integer(b).nil? rescue false)
            a[b.to_i]
          elsif b[0] == ":"
            a[b[1..-1].to_sym]
          else
            a[b]
          end
        end
        rescue
      end
    end
    def write_header(extra = "")
      if !(hh = @formatter.header(extra)).empty?
        @output_file.write hh
      end
    end
    def write_result(info = "")
      if !(rr = @formatter.result(info)).empty?
        @output_file.write rr
      end
    end
    def write_footer(extra = "")
      if !(ff = @formatter.footer(extra)).empty?
        @output_file.write ff
      end
    end
    def write_toc
      cc = 
        @spec.features.map do |f|
          if f.examples.count == 0
            ""
          elsif f.examples.count == 1
            ex = f.examples.first
            tt = !ex.title.empty? ? ex.title : "Example 1"
            "  <a href='##{f.object_id}'>#{f.name}</a>" \
            " - " \
            "<a href='##{ex.object_id}'>#{tt}</a>#{}</a><br/>"
          else
            ee = 
              (0...(f.examples.count)).map do |i|
                e = f.examples[i]
                en = !e.title.empty? ? e.title : "Example #{i}"
                "    <li><a href='##{e.object_id}'>#{en}</a></li>#{CrLf}"
              end
            
            "  <a href='##{f.object_id}'>#{f.name}</a><br/>#{CrLf}" \
            "  <ul>#{CrLf}" \
            "#{ee.join}" \
            "  </ul>"
          end
        end
      
      @output_file.write(
        "  #{CrLf}" \
        "  <div class='title'>Table of Contents</div>#{CrLf}" \
        "  <br/>#{CrLf}" \
        "#{cc.select{|x|!x.empty?}.join("#{CrLf}")}" \
        "  #{CrLf}" \
        "  <br/><br/>#{CrLf}" \
        "  <a href='#top'>Back to top</a>" \
        "  <br/><br/>#{CrLf}  #{CrLf}  #{CrLf}"
      )
    end
    def start_feature(feature, req_headers)
      @output_file.write @formatter.format_feature_begin(feature, req_headers)
    end
    def end_feature
      @output_file.write @formatter.format_feature_end
    end
    def write_request(feature, ex_nbr, request)
      suc = false
      exp = feature.examples[ex_nbr]
      rsp = nil
      txt = nil
      dat = nil
      err = nil
      
      begin
        rsp = request.execute
      rescue Exception => ex
        if ex.is_a?(Interrupt)
          raise ex
        else
          err = "Error: #{ex.message}"
        end
      end
      
      if rsp.nil?
        err = !err.empty? ? err : "Response is NULL."
      elsif (stt = rsp.response.code) == "404"
        err = "URL not found (404)."
      elsif stt == "500"
        err = "Internal server error (500)."
      elsif stt != "200"
        err = "Unexpected response (#{rsp.class}): #{stt}."
      elsif (body = rsp.body).nil?
        err = "Response body is NULL."
      elsif (dat = JSON.parse(body)).nil?
        err = "Response is not a valid JSON."
      elsif (code = dat.fetch("code", nil)).nil?
        err = "JSON field 'code' not found."
      elsif code != 0
        err = "# Error: #{dat.fetch("desc", "(Error description is not available)")}"
        txt = body
      else
        @results[exp.example_id] = dat
        suc = true
        txt = body
      end
      
      
      if suc
        puts "#{exp.url} => #{stt}"
        @succ_count += 1
      else
        inf = err.length > 77 ? err.gsub("\n", "\\\\n")[0..77] + "..." : err
        puts "#{exp.url} => #{rsp.class}#{CrLf}#{inf}"
        @fail_count += 1
      end
      
      @output_file.write(
        @formatter.format_request(
          feature, ex_nbr, @spec.base_url, request.params, txt, err
        )
      )
      
      dat
    end
    
    public
    def start(out_file)
      @output_file  = File.new(out_file, "wb")
      @formatter    = HtmlOutputFormatter.new(@spec.title, @spec.version, @spec.date)
      req_headers   = {"Content-Type" => "application/json"}
      
      write_header \
        "#{CrLf}  #{CrLf}  " \
        "Generated on #{Time.new.strftime("%Y-%m-%d %H:%M:%S")} " \
        "using API Dump v#{Version} Build #{BuildDate}#{CrLf}" \
        "#{@spec.header}  "
      
      write_toc
      
      @spec.features.each do |feature|
        start_feature feature, req_headers
        
        (0...feature.examples.count).each do |i|
          rq = feature.examples[i]
          ip = {}
          rs = nil
          
          if rq.input.is_a?(Hash)
            rq.input.keys.each do |k|
              ip[k] = getterproc(rq.input[k]).call(@results)
            end
          end
          
          rs = 
            write_request(
              feature, 
              i, 
              ApiRequest.new(
                "#{@spec.base_url}#{rq.url}", 
                feature.request_method, 
                ip.merge(rq.params.is_a?(Hash) ? rq.params : {}).to_json, 
                req_headers
              )
            )
          
          if rq.output.is_a?(Hash)
            @results[rq.example_id] = 
              rq.output.keys.inject({}) do |a,b|
                a[b] = getterproc(rq.output[b]).call(rs); a
              end
          end
        end
        
        end_feature
      end
      
      write_result \
        "  " \
        "Total #{@spec.features.count} features, " \
        "#{@succ_count + @fail_count} requests, #{@succ_count} success, " \
        "#{@fail_count} errors."
      write_footer @spec.footer
      
      puts
      puts "Total #{@succ_count + @fail_count} request executed, #{@succ_count} success, #{@fail_count} errors."
      puts
      puts "Output file: #{out_file}"
    end
  end
end


args = ARGV

puts "API Dump v#{ApiDump::Version} Build #{ApiDump::BuildDate}"
puts "Written by Heryudi Praja (mr_orche@yahoo.com)"
puts "This app is licensed under MIT"
puts

if !(1..2).include?(args.count)
  puts "Usage: ruby #{__FILE__} config_file [output_file]"
elsif !File.exist?((cf = args[0]))
  puts "Apispec \"#{cf}\" doesn't exist."
else
  if args.count == 2
    ofn = args[1]
  else
    (ofn = "#{args[0]}")[(-File.extname(args[0]).length)..-1] = ".html"
  end
  
  gen = ApiDump::Generator.new(ApiDump::Specification.load(args[0]))
  gen.start ofn
end
