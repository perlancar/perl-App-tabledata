package App::tabledata;

use 5.010001;
use strict;
use warnings;
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

our %argspecopt_module = (
    module => {
        schema => 'perl::tabledata::modname_with_optional_args*',
        cmdline_aliases => {m=>{}},
        pos => 0,
    },
);

#our %argspecopt_modules = (
#    modules => {
#        schema => 'perl::tabledata::modnames_with_optional_args*',
#    },
#);

sub _list_installed {
    require Module::List::More;
    my $mods = Module::List::More::list_modules(
        "TableData::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
            return_path   => 1,
        });
    my @res;
    for my $mod0 (sort keys %$mods) {
        (my $mod = $mod0) =~ s/\ATableData:://;

        push @res, {
            name => $mod,
            path => $mods->{$mod0}{module_path},
        };
     }
    \@res;
}

$SPEC{tabledata} = {
    v => 1.1,
    summary => 'Show content of TableData modules (plus a few other things)',
    args => {
        %argspecopt_module,
        action => {
            schema  => ['str*', {in=>[
                'list_actions',
                'list_installed',
                #'list_cpan',
                'dump_as_aoaos',
                'dump_as_aohos',
                'dump_as_csv',
                'list_columns',
                'count_rows',
                'pick_rows',
                'head',
                #'stat',
            ]}],
            default => 'dump_as_aoaos',
            cmdline_aliases => {
                actions => {
                    summary=>'List available actions (alias for --action=list_actions)',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_actions' },
                },
                L => {
                    summary=>'List installed TableData::* (alias for --action=list_installed)',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                #C => {
                #    summary=>'List TableData::* on CPAN',
                #    is_flag => 1,
                #    code => sub { my $args=shift; $args->{action} = 'list_cpan' },
                #},
                H => {
                    summary=>'Get the first N row(s) (alias for --action=head)',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'head' },
                },
                R => {
                    summary=>'Pick random rows from an TableData module',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'pick_rows' },
                },
                #S => {
                #    summary=>'Show statistics contained in the TableData module',
                #    is_flag => 1,
                #    code => sub { my $args=shift; $args->{action} = 'stat' },
                #},
            },
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        num => {
            summary => 'Number of rows to get (e.g. for pick_rows or head action)',
            schema => 'posint*',
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        #lcpan => {
        #    schema => 'bool',
        #    summary => 'Use local CPAN mirror first when available (for -C)',
        #},
    },
    examples => [
    ],
};
sub tabledata {
    my %args = @_;
    my $action = $args{action} // 'dump';

    if ($action eq 'list_actions') {
        return [200, "OK", $SPEC{tabledata}{args}{action}{schema}[1]{in}];
    }

    if ($action eq 'list_installed') {
        my @rows;
        for my $row (@{ _list_installed() }) {
            push @rows, $args{detail} ? $row : $row->{name};
        }
        return [200, "OK", \@rows];
    }

    return [400, "Please specify module"] unless defined $args{module};

    require Module::Load::Util;
    my $obj = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"TableData"}, $args{module});

    if ($action eq 'pick_rows') {
        return [200, "OK", [$obj->pick_items(n=>$args{num})]];
    }

    if ($action eq 'head') {
        my @rows;
        my $i = 0;
        $obj->each_item(
            sub {
                push @rows, $_[0];
                return 0 if ++$i >= $args{num};
                1;
            });
        return [200, "OK", \@rows, {
            'table.fields'=>[$obj->get_column_names],
        }];
    }

    if ($action eq 'list_columns') {
        return [200, "OK", [$obj->get_column_names]];
    }

    if ($action eq 'count_columns') {
        return [200, "OK", scalar $obj->get_column_count];
    }

    if ($action eq 'count_rows') {
        return [200, "OK", scalar $obj->get_row_count];
    }

    if ($action eq 'dump_as_csv') {
        return [200, "OK", scalar $obj->as_csv];
    }

    if ($action eq 'dump_as_aohos') {
        return [200, "OK", [$obj->get_all_rows_hashref], {
            'table.fields'=>[$obj->get_column_names],
        }];
    }

    # dump_as_aoaos
    return [200, "OK", [$obj->get_all_rows_arrayref], {
        'table.fields'=>[$obj->get_column_names],
    }];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See the included script L<arraydata>.


=head1 ENVIRONMENT


=head1 SEE ALSO

L<ArrayData> and C<ArrayData::*> modules.
