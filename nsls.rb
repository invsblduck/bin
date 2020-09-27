#!/usr/bin/ruby

require 'yaml'

if Process.euid != 0
  $stderr.puts "please run as root"
  exit 1
end

def err (msg)
  $stderr.puts "#{File.basename $0}: #{msg}"
end

def get_ns_inode (pid, type)
  begin
    File.readlink "/proc/#{pid}/ns/#{type}"
  rescue => e
    err "couldn't read inode link for #{pid}: #{e}"
  end
end

def read_proc_file (path)
  begin
    open(path, 'rb') do |f|
      f.read.gsub(/(\x00|\n)/, ' ').strip  # remove null bytes and newlines
    end
  rescue => e
    err "couldn't read proc file '#{path}': #{e}"
  end
end

def get_cmdline (pid)
  cmd = read_proc_file "/proc/#{pid}/cmdline"
  if cmd.empty?  # fallback
    cmd = read_proc_file "/proc/#{pid}/comm"
  end
  cmd
end

def get_ppid (pid)
  begin
    (read_proc_file("/proc/#{pid}/stat").split)[3]  # 4th field is PPID
  rescue => e
    err "couldn't get ppid of #{pid}: #{e}"
  end
end

def docker? (cmd)
  cmd =~ %r[^((/\w+/){1,})?(containerd(-shim)?|dockerd?)]
end

# find namespace types from systemd process
ns_types = Dir['/proc/1/ns/*'].collect { |e| File.basename(e) }

# find inode numbers for systemd namespaces
systemd_inodes = ns_types.map do |t|
  get_ns_inode 1, t
end

#
# iterate all processes and find non-systemd ones!
#
begin
  pids_with_ns = Dir['/proc/[1-9]*'].inject([]) do |pid_list, pid_dir|
    # look at each pid
    pid = File.basename pid_dir
    cmd = get_cmdline pid
    begin
      # look at each of its namespaces
      uniq_ns = Dir["#{pid_dir}/ns/*"].inject([]) do |ns_list, nslink|
        if inode = get_ns_inode(pid, File.basename(nslink))
          # collect it if non-systemd
          unless systemd_inodes.include? inode
            ns_list << inode
          end
        end
        ns_list  # return memo
      end
    rescue => e
      err "couldn't enumerate namespaces for #{pid}: #{e}"
    end

    if uniq_ns.any?
      # check if pid is child of docker
      if docker? get_cmdline(get_ppid(pid))
        cmd = "(docker) #{cmd}"
      end
      pid_list << {  # collect dictionary of details
        'cmd' => cmd,
        'pid' => pid,
        'ns'  => uniq_ns,
      }
    end

    pid_list  # return memo
  end
rescue => e
  err "couldn't enumerate pids in /proc: #{e}"
end

# print collected data as yaml
puts pids_with_ns.to_yaml
