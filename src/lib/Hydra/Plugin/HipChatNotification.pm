package Hydra::Plugin::HipChatNotification;

use strict;
use parent 'Hydra::Plugin';
use LWP::UserAgent;
use Hydra::Helper::CatalystUtils;

sub buildFinished {
    my ($self, $build, $dependents) = @_;

    my $cfg = $self->{config}->{hipchat};
    my @config = ref $cfg eq "ARRAY" ? @$cfg : ($cfg);

    my $baseurl = $self->{config}->{'base_uri'} || "http://localhost:3000";

    # Figure out to which rooms to send notification.  For each email
    # room, we send one aggregate message.
    my %rooms;
    foreach my $b ($build, @{$dependents}) {
        my $prevBuild = getPreviousBuild($b);
        my $jobName = showJobName $b;

        foreach my $room (@config) {
            next unless $jobName =~ /^$room->{jobs}$/;

            # If build is cancelled or aborted, do not send email.
            next if $b->buildstatus == 4 || $b->buildstatus == 3;

            # If there is a previous (that is not cancelled or aborted) build
            # with same buildstatus, do not send email.
            next if defined $prevBuild && ($b->buildstatus == $prevBuild->buildstatus);

            $rooms{$room->{room}} //= { room => $room, builds => [] };
            push @{$rooms{$room->{room}}->{builds}}, $b;
        }
    }

    # Send a message to each room.
    foreach my $roomId (keys %rooms) {
        my $room = $rooms{$roomId};
        my @deps = grep { $_->id != $build->id } @{$room->{builds}};

        my $imgBase = "http://hydra.nixos.org";
        my $img =
            $build->buildstatus == 0 ? "$imgBase/static/images/checkmark_16.png" :
            $build->buildstatus == 2 ? "$imgBase/static/images/dependency_16.png" :
            $build->buildstatus == 4 ? "$imgBase/static/images/cancelled_16.png" :
            "$imgBase/static/images/error_16.png";

        my $msg = "";
        $msg .= "<img src='$img'/> ";
        $msg .= "Job <a href='$baseurl/job/${\$build->project->name}/${\$build->jobset->name}/${\$build->job->name}'>${\showJobName($build)}</a>";
        $msg .= " (and ${\scalar @deps} others)" if scalar @deps > 0;
        $msg .= ": <a href='$baseurl/build/${\$build->id}'>" . showStatus($build) . "</a>";

        print STDERR "sending hipchat notification to room $roomId: $msg\n";

        my $ua = LWP::UserAgent->new();
        my $resp = $ua->post('https://api.hipchat.com/v1/rooms/message?format=json&auth_token=' . $room->{room}->{token}, {
            room_id => $roomId,
            from => 'Hydra',
            message => $msg,
            message_format => 'html',
            notify => 0,
            color => $build->buildstatus == 0 ? 'green' : 'red' });

        print STDERR $resp->status_line, ": ", $resp->decoded_content,"\n" if !$resp->is_success;
    }
}

1;