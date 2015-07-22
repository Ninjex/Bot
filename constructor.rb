require_relative 'req.rb'

class BotConfig
  def initialize(nick, server_addr, port, server_pass=nil, channel)
    @nick, @server_addr = nick, server_addr
    @port, @server_pass = port, server_pass
    @channel = channel
  end
end

class Bot < BotConfig
  def info
    nick =      "| Nick:     | #{@nick}"
    server =    "| Server:   | #{@server_addr}"
    port =      "| Port:     | #{@port}"
    channels =  "| Channels: | #{@channel}"
    title = 'Bot Schema'
    l = [nick, server, port, channels].group_by(&:size).max.last[0].size
    _ = ((l - title.size) / 2)
    puts " " * _ + title.green + " " * _

    bar = "+".green + "-".green * l + "+".green
    puts bar
    [nick,server,port,channels].each do |i|
      diff = l - i.size + 1
      puts i.green + " " * diff + "|".green
    end
    puts bar;puts
  end

  def send(command)
    puts "--> #{command}".cyan
    @irc.puts(command)
  end

  def connect
    puts "[+] Connecting to: #{@server_addr}".brown
    begin
      @irc = TCPSocket.open(@server_addr, @port)
    rescue SocketError => err
      puts "Socket Error: #{err}"
    end
    identified, running = false, true
    if identified == false
      sleep(2)
      send("PASS #{@server_pass}") if @server_pass
      send("raw CAP REQ :twitch.tv/membership") if @server_addr == 'irc.twitch.tv'
      send("USER #{@nick} #{@nick} #{@nick} :#{@nick}")
      send("NICK #{@nick}")
      identified = true
    end

    while running
      server_data = @irc.gets
      if server_data
        print "<-- #{server_data}".magenta
        @input = server_data.split(' ')

        send("PONG #{@input[1]}") if @input[0] == 'PING'
        send("JOIN #{@channel}") if @input[1] == '376'
        if @input[0] == 'ERROR' and @input[1] == ':Closing' and @input[2] == 'Link:'
          abort("[!] Your host: #{@input[3]} is banned from #{@server_addr}".brown)
        end

        @chan = @input[2] if @input.size >= 2
        @com = @input[3] if @input.size >= 3

        if @com == '::exit'
          puts "[+] Preparing for exit".brown
          send("QUIT :I go bye bye")
          abort("[+] Dead...".red)
        end

      else
        sleep(0.5)
      end # server socket empty?
    end # while loop
  end # connect method
end # Bot class

def bot_construct(bot)
  return Bot.new(bot[:nick], bot[:server], bot[:port], bot[:pass], bot[:channels])
end
