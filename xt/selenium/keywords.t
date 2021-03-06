# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

use 5.14.0;
use strict;
use warnings;

use FindBin qw($RealBin);
use lib "$RealBin/../lib", "$RealBin/../../local/lib/perl5";

use Test::More "no_plan";

use QA::Util;

my ($sel, $config) = get_selenium();

# Create keywords. Do some cleanup first if necessary.

log_in($sel, $config, 'admin');
go_to_admin($sel);
$sel->click_ok("link=Keywords");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Select keyword");

# If keywords already exist, delete them to not disturb the test.

my $page = $sel->get_body_text();
my @keywords = $page =~ m/(key-selenium-\w+)/gi;

foreach my $keyword (@keywords) {
    my $url = $sel->get_attribute("link=$keyword\@href");
    $url =~ s/action=edit/action=del/;
    $sel->click_ok("//a[\@href='$url']");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Delete Keyword");
    $sel->click_ok("delete");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Keyword Deleted");
}

# Now let's create our first keyword.

go_to_admin($sel);
$sel->click_ok("link=Keywords");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Select keyword");
$sel->click_ok("link=Add a new keyword");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Add keyword");
$sel->type_ok("name", "key-selenium-kone");
$sel->type_ok("description", "Hopefully an ice cream");
$sel->click_ok("create");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("New Keyword Created");

# Try create the same keyword, to check validators.

$sel->click_ok("link=Add a new keyword");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Add keyword");
$sel->type_ok("name", "key-selenium-kone");
$sel->type_ok("description", "FIX ME!");
$sel->click_ok("create");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Keyword Already Exists");
my $error_msg = trim($sel->get_text("error_msg"));
ok($error_msg eq 'A keyword with the name key-selenium-kone already exists.', 'Already created keyword');
$sel->go_back_ok();
$sel->wait_for_page_to_load(WAIT_TIME);

# Create a second keyword.

$sel->type_ok("name", "key-selenium-ktwo");
$sel->type_ok("description", "FIX ME!");
$sel->click_ok("create");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("New Keyword Created");

# Again test validators.

$sel->click_ok("link=key-selenium-ktwo");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Edit keyword");
$sel->type_ok("name", "key-selenium-kone");
$sel->type_ok("description", "the second keyword");
$sel->click_ok("update");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Keyword Already Exists");
$error_msg = trim($sel->get_text("error_msg"));
ok($error_msg eq 'A keyword with the name key-selenium-kone already exists.', 'Already created keyword');
$sel->go_back_ok();
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Edit keyword");
$sel->type_ok("name", "key-selenium-ktwo");
$sel->click_ok("update");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Keyword Updated");

# Add keywords to bugs

file_bug_in_product($sel, "TestProduct");
$sel->select_ok("component", "TestComponent");
$sel->type_ok("keywords", "key-selenium-kone");
my $bug_summary = "It's a beautiful day";
$sel->type_ok("short_desc", $bug_summary);
$sel->type_ok("comment", "This bug is to test keywords");
my $bug1_id = create_bug($sel, $bug_summary);

file_bug_in_product($sel, "TestProduct");
$sel->select_ok("component", "TestComponent");
$sel->type_ok("keywords", "key-selenium-kone, key-selenium-ktwo");
my $bug_summary2 = "Radio gaga";
$sel->type_ok("short_desc", $bug_summary2);
$sel->type_ok("comment", "This bug is also to test keywords, like bug $bug1_id");
my $bug2_id = create_bug($sel, $bug_summary2);

# Now make sure these bugs correctly appear in buglists.

open_advanced_search_page($sel);
$sel->remove_all_selections("product");
$sel->remove_all_selections("bug_status");
$sel->type_ok("keywords", "key-selenium-kone");
$sel->click_ok("Search");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Bug List");
$sel->is_text_present_ok("2 bugs found");

$sel->click_ok("link=Search");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Search for bugs");
$sel->remove_all_selections("product");
$sel->remove_all_selections("bug_status");
# Try with a different case than the one in the DB.
$sel->type_ok("keywords", "key-selenium-ktWO");
$sel->click_ok("Search");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Bug List");
$sel->is_text_present_ok("One bug found");

$sel->click_ok("link=Search");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Search for bugs");
$sel->remove_all_selections("product");
$sel->remove_all_selections("bug_status");
# Substrings also work for keywords.
$sel->type_ok("keywords", "selenium");
$sel->click_ok("Search");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Bug List");
$sel->is_text_present_ok("2 bugs found");

# Make sure describekeywords.cgi works as expected.

$sel->click_ok("link=$bug_summary");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_like(qr/^$bug1_id /);
$sel->click_ok("link=Keywords:");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Bugzilla Keyword Descriptions");
$sel->is_text_present_ok("key-selenium-kone");
$sel->is_text_present_ok("Hopefully an ice cream");
$sel->is_text_present_ok("key-selenium-ktwo");
$sel->is_text_present_ok("the second keyword");
$sel->click_ok('//a[@href="buglist.cgi?keywords=key-selenium-kone"]');
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Bug List");
$sel->is_element_present_ok("link=$bug1_id");
$sel->is_element_present_ok("link=$bug2_id");
$sel->is_text_present_ok("2 bugs found");
$sel->go_back_ok();
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->click_ok('//a[@href="buglist.cgi?keywords=key-selenium-ktwo"]');
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Bug List");
$sel->is_element_present_ok("link=$bug2_id");
$sel->is_text_present_ok("One bug found");
logout($sel);
