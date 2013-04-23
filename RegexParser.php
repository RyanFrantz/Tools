<?php

# TODO: Documentation.  Add in error handling and support for additional regexiness

# NOTE: I'm tailoring this for Nagios but I can imagine it being useful in other contexts

class RegexParser {

    function __construct( $regex ) {
        if ( $regex ) {
            # do the caller a favor and check that the regex is valid
            $valid_regex = self::isValidRegex( $regex );
            if ( $valid_regex ) {
                return true;
            } else {
                return false;
            }
        } else {
            print "Missing argument! Gimme some regex to chew on!\n";
            return false;
        }
    }

    public function isValidRegex( $regex ) {
        # match strings like 'web0[01][0-9][0-9].ny4' but not 'web0[01]foo[0-9][0-9].ny4'; we're not that smart, yet ;)
        if ( preg_match( '/(^[a-z0-9]+)(\[.+?\]+)(\.\w+)/', $regex, $matches ) ) {
            $host_prefix = $matches[1];
            $domain = $matches[3];
            return true;
        } else {
            print "I don't understand the regex pattern '$regex'! I can handle one more more character classes with sets and/or ranges of digits (i.e. 'web0[01][2-4][567].ny4').\n";
            return false;
        }
    }

    public function parse_character_class( $regex ) {
        if ( preg_match( '/(\[\d+\])/', $regex, $matches ) ) {
            # we have a set (i.e. [135])
            $just_numbers =  preg_replace( '/\[|\]/', '', $matches[1] );    # drop the square brackets
            $split_numbers = preg_split( '//', $just_numbers );    # split the characters into an array of characters
            $number_set =  preg_grep( '/\d/', $split_numbers );
            $number_set = array_values( $number_set );  # reindex the array (i.e. so the values start at [0]; pedantry FTW!
            return $number_set;
        } elseif ( preg_match( '/(\[\d-\d\])/', $regex, $matches ) ) {
            # we have a range (i.e. [0-9])
            $just_numbers =  preg_replace( '/\[|\]/', '', $matches[1] );    # drop the square brackets
            $split_numbers = preg_split( '//', $just_numbers );    # split the characters into an array of characters
            $numbers =  preg_grep( '/\d/', $split_numbers );

            # make certain the last number is greater than the first, then determine the numbers in the range, inclusize
            $count = count( $numbers );
            if ( $count != 2 ) {
                print "Hey! I thought this was a range!  I only expected 2 numbers but see $count instead!";
                return false;   # avec prejudice
            }
            $indexes = array_keys( $numbers );  # get the array indexes
            $first = $numbers[$indexes[0]];
            $last = $numbers[$indexes[1]];
            if ( $first < $last ) {
                $number_range = range( $first, $last );
                $number_range = array_values( $number_range );    # reindex the array
            }

            return $number_range;
        }
        # we should also return something not nice when we didn't match what we expected...
    }

    public function parseRegex( $regex ) {
        # matches strings like 'web[01][2-4][56]' but not 'web[01][2-4]foo[56]'; the 'foo' will be silently ignored
        if ( preg_match( '/(^[a-z0-9]+)(\[.+?\]+)(\.\w+)/', $regex, $matches ) ) {
            $host_prefix = $matches[1];
            $domain = $matches[3];
            preg_match_all( '/\[.+?\]+/', $matches[2], $class_matches ); 
            $character_classes = $class_matches[0];
        }
        $host_suffixes = array();   # the array we'll use to store our host suffixes (i.e. '01', '02', etc.)
        foreach ( $character_classes as $character_class ) {
            $suffix_count = count( $host_suffixes );
            $number_range = $this->parse_character_class( $character_class );
            if ( $suffix_count == 0 ) {
                # this must be the first loop through the character class(es); initialize the array
                $host_suffixes =  $number_range;    # already an array
            } else {
                $temp_array = array();  # we need a temporary place to build up the host suffixes
                $returned_number_count = count( $number_range );
                # iterate over the stored suffixes and concatenate the next batch of strings to them, in turn
                foreach ( $host_suffixes as $host_suffix ) {
                    foreach ( $number_range as $number ) {
                        $new_host_suffix =  $host_suffix . $number; 
                        array_push( $temp_array, $new_host_suffix );
                    }
                }
                $host_suffixes = $temp_array;   # replace the array with new values that we've built up
            }
        }

        $expanded_hostnames = array();
        foreach ( $host_suffixes as $host_suffix ) {
            $expanded_hostname = sprintf( "%s%s%s", $host_prefix, $host_suffix, $domain );
            array_push( $expanded_hostnames, $expanded_hostname );
        }

        return $expanded_hostnames;

    }

}

?>
