requires 'perl', '5.010_001';
requires 'parent';
requires 'Filesys::Notify::Simple';

# Linux::Inotify2
# Mac::FSEvents
# Filesys::Notify::KQueue
# Win32::ChangeNotify

on 'test' => sub {
    requires 'Test::More', '0.98';
};

