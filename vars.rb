#!/usr/bin/env ruby

# Copyright (c) 2011-2012 n0pe. 
# This file is licensed under the The GNU General Public License version 3 or later. 
# See the COPYRIGHT file.

begin
	require 'getoptlong'
	require 'ruport'
rescue LoadError => e
	puts "[ERROR] #{e}"
end

class Vars
	
	def initialize(opts)
	
		@search = ""
		
		begin
			opts.each do |opt, arg|
				case opt
					when /--dir|-d/ then @path = arg
					when /--max|-m/ then @limit = arg
					when /--log|-l/ then @log_name = arg
					when /--search|-s/ then @search = arg
					when /--function|-f/ then @call = 1
					when /--verbose|-v/ then @verbose = 1
				end
			end
		rescue
			usage
		end
		
		@php = []
		@functions = []
		@list = 0
		@count = 0
		@vars = []
		@eval = ['system','exec','shell_exec','passthru']
		
		usage if !@path
		fatal ("\n"+@path+" is not a directory\n\n") if !File.directory?(@path)
		puts "\n[+] Adjusting path" if @verbose
		
		@path += "/" if @path[-1] != "/"
		Dir.glob(@path+"*.php").each do |n|
			@php.push(n)
			@list+=1
		end
		puts "\n[+] Total files: #{@list}\n\n"
		
		if @call
			dangerous
		else
			find_var
		end
	end
	
	def find_var
		@php.each do |files|
			file = File.new(files, "r")
			puts "[+] Checking #{files} ..." if @verbose
			while (line = file.gets)
				@count+=1
				line.match(/\$_[A-Z]+\[.+?\]/) do |m|
					if @search && m != nil
						if m.to_s.match(/#{@search}.*?/)
							@vars.push("#{@count}|#{m}|#{files}")
						end
					else
						m == nil ? next : @vars.push("#{@count}|#{m}|#{files}")
					end
				end
			end
			file.close
			@count = 0
		end
		puts "\n"
		if @log_name != nil 
			write_log(1)
		else
			puts "[+] Searching of variable #{@search}\n\n" if !@search.empty?
			table = Ruport::Data::Table.new :column_names => [:Name, :Type, :Source, :Line]
			@vars.uniq.each do |var|
				tmp = var.split('|')
				line = tmp[0]
				name = tmp[1]
				files = tmp[2]
			
				content = var[/\$_[A-Z]+\[.+?\]/]
				content = content.gsub!(/\$_[A-Z]+/, "")
			
				type = var[/\$\_[A-Z]+/]
			
				type = type.gsub(/\$_/, '')
			
				if !@search.empty?
					if content =~ /#{@search}/
						table << [name, type, files, line]
					end
				else
					table << [name, type, files, line]
				end
			end
			puts table.to_text
		end
	end
	
	def dangerous
		table = Ruport::Data::Table.new :column_names => [:Name, :Source, :Line]
		@php.each do |files|
			file = File.new(files, "r")
			puts "[+] Checking #{files} ..." if @verbose
			while (line = file.gets)
				@count+=1
				@eval.each{|fe|
					line.match(/#{fe}\(.*?\)/) do |m|
						if @search.empty?
							content = m.to_s[/#{fe}/]
							@functions.push("#{content}|#{files}|#{@count}")
							table << [content, files, @count] if m != nil
						else
							if m.to_s.match(/#{@search}.*?/)
								@functions.push("#{m}|#{files}|#{@count}")
								table << [m, files, @count]
							end
						end
								
					end
				}
			end
			@count=0
		end
		write_log(0) if @log_name != nil
		puts table.to_text if @log_name == nil
	end
	
	
	def write_log(wi)
		puts "[+] Writing log file..." if @verbose
		raise "Can't open file #{@log_name}" if !@log = File.new(@log_name, "w+")
		@log.write("<html><head><link rel='stylesheet' type='text/css' href='class.css'/><title>Vars Log</title></head><body>")
		if wi != 0
			@log.write("<table><tr><th>Name</th><th>Type</th><th>Source</th><th>Line</th></tr>")
		else
			@log.write("<table><tr><th>Content</th><th>Source</th><th>Line</th></tr>")
		end
		
		if wi == 1
			@vars.uniq.each do |var|
		
				tmp = var.split('|')
				line = tmp[0]
				name = tmp[1]
				files = tmp[2]
			
			
				type = var[/\$\_[A-Z]+/]
			
				type = type.gsub(/\$_/, '')
			
				@log.write("<tr><th class='spec'>#{name}</th><td>#{type}</td><td>#{files}</td><td>#{line}</td></tr>")
			end
		else
			@functions.uniq.each do |f|
				tmp = f.split('|')
				content = tmp[0]
				files = tmp[1]
				line = tmp[2]
				
				@log.write("<tr><th class='spec'>#{content}</th></td><td>#{files}</td><td>#{line}</td></tr>")
			end
		end
				
		@log.write("</table></body></html>")
		puts "[+] Log file successfully written\n\n"
		puts "Open log file? Y/n"
		chose = gets.chomp!
		if chose == "Y" || chose == "y" || chose == ""
			system("xdg-open", Dir.pwd+"/#{@log_name}")
		else
			exit
		end
	end
	
	def show_var
		puts "[+] Searching of variable #{@search}\n\n" if !@search.empty?
		table = Ruport::Data::Table.new :column_names => [:Name, :Type, :Source, :Line]
		@vars.uniq.each do |var|
			tmp = var.split('|')
			line = tmp[0]
			name = tmp[1]
			files = tmp[2]
			
			content = var[/\$_[A-Z]+\[.+?\]/]
			content = content.gsub!(/\$_[A-Z]+/, "")
			
			type = var[/\$\_[A-Z]+/]
			
			type = type.gsub(/\$_/, '')
			
			if !@search.empty?
				if content =~ /#{@search}/
					table << [name, type, files, line]
				end
			else
				table << [name, type, files, line]
			end
		end
		puts table.to_text
	end
	
	def fatal(wtf)
		puts wtf
		exit(0)
	end
	
	def usage
		puts "\nUsage ./vars.rb -d [path] [options]\n\n"
		exit(0)
	end
	
	
end

opts = GetoptLong.new(
  ['--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--dir', '-d', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--max', '-m', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--log', '-l', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--search', '-s', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--function', '-f', GetoptLong::NO_ARGUMENT ],
  [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ]
)

start = Vars.new(opts)
