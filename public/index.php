<?php

// TVR Code
//
// Redirect the user to the appropriate page, based on what ZenCart page
// they were looking for.

$host = $_SERVER['HTTP_HOST'];
$path = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');

// Send a 301 redirect instead of a 302
header("HTTP/1.1 301 Moved Permanently");

// Forward the wtk and ct arguments on, so that we can track users
// coming from marketing efforts

$args = array();

if (isset($_GET['wtk'])) {
    array_push($args, 'wtk=' . ereg_replace("[^0-9a-z]", "", $_GET['wtk']));
}

if (isset($_GET['ct'])) {
    array_push($args, 'ct=' . ereg_replace("[^0-9a-z]", "", $_GET['ct']));
}

if (isset($_GET['ga'])) {
    array_push($args, 'ga=' . ereg_replace("[^0-9a-z]", "", $_GET['ga']));
}

if (isset($_GET['ya'])) {
    array_push($args, 'ya=' . ereg_replace("[^0-9a-z]", "", $_GET['ya']));
}

if (count($args) > 0) {
    $arg_string = '?' . implode('&', $args);
} else {
    $arg_string = '';
}

$main_page = $_GET['main_page'];

// Product page
if ($main_page == 'product_info') {
    $products_id = (int) $_GET['products_id'];
	// Special case gift certificate product page
	if ($products_id == 3603) {
		$url = "store/giftcert/$products_id$arg_string";
	} else {
		$url = "store/video/$products_id$arg_string";
	}
    header("Location: http://$host$path/$url");
    exit;
}

// Product review page
if ($main_page == 'product_reviews_write') {
    $products_id = (int) $_GET['products_id'];
	$url = "store/review/$products_id$arg_string";
    header("Location: http://$host$path/$url");
    exit;
}

// Category page
if ($main_page == 'index' && isset($_GET['cPath'])) {

	$category = $_GET['cPath'];
    // Data validation -- drop undesired characters
    $category = ereg_replace("[^0-9_]", "", $category);
	// Railscart just needs the final category
	$category = split('_', $category);
	$category = $category[count($category) - 1];

	$url = "store/category/$category$arg_string";
    header("Location: http://$host$path/$url");
    exit;
}

// Search page
if ($main_page == 'advanced_search_result') {
	$keyword = $_GET['keyword'];
    // Data validation -- drop undesired characters
    $keyword = ereg_replace(" ", "+", $keyword);
    $keyword = ereg_replace("[^a-zA-Z0-9_+]", "", $keyword);

	$arg_string = str_replace('?', '&', $arg_string);

	$url = "store/search?q=$keyword$arg_string";
    header("Location: http://$host$path/$url");
    exit;
}

// Bunch of simple content pages
$static_lookup = array('howitworks'           => 'store/how_it_works',
					   'testimonials'         => 'store/testimonials',
					   'blog'                 => 'store/smartblog',
					   'aboutus'              => 'store/about_us',
					   'help'                 => 'help',
					   'shopping_cart'        => 'cart',
					   'account'              => 'customer',
					   'account_edit'         => 'customer',
					   'address_book'         => 'customer',
					   'address_book_process' => 'customer',
					   'account_password'     => 'customer',
					   'account_newsletters'  => 'customer',
					   'logoff'               => 'customer/logout',
					   'account_history'      => 'customer/order_history',
					   'account_history_info' => 'customer/order_history',
					   'suggest'              => 'store/suggest',
					   'contact_us'           => 'store/contact_us',
					   'products_new'         => 'store/new',
					   'featured_products'    => 'store/top_rated',
					   'conditions'           => 'store/conditions',
					   'privacy'              => 'store/privacy',
					   'help_howitworks'      => 'help/how_it_works',
					   'help_payment'         => 'help/payment',
					   'help_legal'           => 'help/legal',
					   'help_technical'       => 'help/technical',
					   'help_other'           => 'help/other');

if ($static_lookup[$main_page]) {
	$url = $static_lookup[$main_page] . $arg_string;
    header("Location: http://$host$path/$url");
    exit;
}

// Default: Go to front page
header("Location: http://$host$path/store$arg_string");
