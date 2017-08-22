#!/usr/bin/perl
$|++;

# check for Ops::Helper
eval { require Ops::Helper };
$helper = ($@) ? 0 : 1;

# add krb5 to $PATH
$ENV{'PATH'} .= ":/usr/kerberos/bin:/usr/kerberos/sbin"
    if ($ENV{'PATH'} !~ /kerberos/);

# get destination host
(@ARGV) ? ($host,$ping) = @ARGV : die "usage: $0 <host>\n";

# get TGT if necessary
#system ("klist 2>&1 |grep -q 'No cred'");

#unless ($? >> 8 > 0) {   # don't want grep match
#    system ("kinit -f");
#    exit 1 if ($? >> 8 > 0);
#}

# fortune is my friend
system ("which fortune >/dev/null 2>&1");

if ($? >> 8 == 0) {

    $cmd = "fortune -n 150 -s";

    system ("which cowsay >/dev/null 2>&1");
    $cmd .= " |cowsay -f tux" unless ($? >> 8 != 0);

    system ("$cmd > ~/.motd");
}
else {

    open(MOTD, "> $ENV{'HOME'}/.motd");
    print MOTD << 'EOF';
             ,        ,
            /(        )`
            \ \___   / |
            /- _  `-/  '
           (/\/ \ \   /\    FreeBSD!
           / /   | `    \
           O O   ) /    |
           `-^--'`<     '
          (_.)  _  )   /
           `.___/`    /
             `-----' /
<----.     __ / __   \
<----|====O)))==) \) /====
<----'    `--' `.__,' \
             |        |
              \       /
        ______( (_  / \______
      ,'  ,-----'   |        \
      `--{__________)        \/

EOF

    close MOTD;
}

# remove host from ~/.ssh/known_hosts
Ops::Helper::cleanse_known_hosts_file($host) if ($helper);

if ($ping) {

    open(PING, "ping $host |");
    print "Waiting for host to come up...";
    while (<PING>) {
        if (/^64 bytes/) {
            $up=1;
            last;
        }
    }
    close PING;
    exit 1 unless ($up);
    print "OK!\n";

    print "Waiting for sshd...";
    my $open;
    while ( ! $open) {

        system ("nc -z $host 22");
        ($? >> 8 > 0) ? sleep 1 : last;
    }
    print "OK!\n";
}

# find out which host we're on
chomp($current_host = `hostname`);

# scp shiz to target $host
if ($current_host == 'archie') {

    $dotfiles = '/git/invsblduck/fakecloud_configs/dotfiles';
    foreach (qw(.vim* .toprc .bash* .inputrc .dircolors)) {
        push @files, "$dotfiles/$_";
    }
    push @files, ('/git/invsblduck/bin/g2sh.pl', '~/.motd');
}
else {

    @files = qw( ~/g2sh.pl ~/.vimrc ~/.vim ~/.toprc ~/.bash_profile
                ~/.bashrc ~/.bash ~/.inputrc ~/.dircolors ~/.motd );
}

#system ("rsync -aLk -i --info=flist1,stats0" .
system ("rsync -aLk -i " .
        " --exclude='**/*.swp' --exclude='**/*.un~' @files $host:");

# ssh your bad self there ...
exec ("ssh $host") or die "could not exec(): $!\n";
