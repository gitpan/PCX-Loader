use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'PCX::Loader',
    'VERSION_FROM'      => 'Loader.pm', # finds $VERSION
    'PREREQ_PM'         => {}, 
);
