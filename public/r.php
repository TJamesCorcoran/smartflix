<?php

// TVR Code
//
// Redirect the user to the appropriate page, based on the arguments;
// this is a holdover from the ZenCart days, and now redirects to the
// appropriate railscart page
//
// ie OLD: p=<id> => index.php?main_page=product_info&products_id=<id>
//    NEW: p=<id> => /store/product/<id>
//
// Currently supported:
//
// p => products page
// c => category page
// k => shopping cart
// b => blog
// t => email preferences
// r => review writing
// g => gift certificate redemption

$host = $_SERVER['HTTP_HOST'];
$path = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');

// Send a 301 redirect instead of a 302
header("HTTP/1.1 301 Moved Permanently");

// Forward the wtk and ct arguments on, so that we can track users
// coming from marketing efforts

if (isset($_GET['wtk'])) {
    $wtk = '?wtk=' . ereg_replace("[^0-9a-z]", "", $_GET['wtk']);
} else {
    $wtk = "";
}

if (isset($_GET['ct'])) {
    $ct = '?ct=' . ereg_replace("[^0-9a-z]", "", $_GET['ct']);
} else {
    $ct = "";
}

// Link to a product page

if (isset($_GET['p'])) {

    $products_id = (int) $_GET['p'];
    // $url = "index.php?main_page=product_info&products_id=$products_id$wtk$ct";
	// Special case gift certificate product page
	if ($products_id == 3603) {
		$url = "store/giftcert/$products_id$wtk$ct";
	} else {
		$url = "store/video/$products_id$wtk$ct";
	}
    header("Location: http://$host$path/$url");
    exit;
}

// Link to a category page

if (isset($_GET['c'])) {

    $category = $_GET['c'];

    // Data validation -- drop undesired characters
    $category = ereg_replace("[^0-9_]", "", $category);
	// Railscart just needs the final category
	$category = split('_', $category);
	$category = $category[count($category) - 1];

    // $url = "index.php?main_page=index&cPath=$category$wtk$ct";
	$url = "store/category/$category$wtk$ct";
    header("Location: http://$host$path/$url");
    exit;
}

// Link to shopping basket

if (isset($_GET['k'])) {

    // $url = "index.php?main_page=shopping_cart";
	$url = "cart";
    header("Location: http://$host$path/$url");
    exit;
}

// Link to a blog post

if (isset($_GET['b'])) {

    $blog_id = (int) $_GET['b'];
    // $url = "index.php?main_page=blog&p=$blog_id$wtk$ct";
	$url = "store/smartblog";
    header("Location: http://$host$path/$url");
    exit;
}

// Link to a customer's email preferences page

if (isset($_GET['t'])) {

    $token = $_GET['t'];

    // Data validation -- drop undesired characters
	// This token doesn't work any more, they'll have to log in
    $token = ereg_replace("[^a-zA-Z0-9:]", "", $token);

    // $url = "index.php?main_page=account_newsletters&t=$token";
	$url = "customer/email_prefs";
    header("Location: http://$host$path/$url");
    exit;
}

// Link to a customer review writing page

if (isset($_GET['r'])) {

    $token = $_GET['r'];

    // Data validation -- drop undesired characters
	// This token doesn't work any more, they'll have to log in
    $token = ereg_replace("[^a-zA-Z0-9:]", "", $token);

    $pid = (int) $_GET['rp'];

    // $url = "index.php?main_page=product_reviews_write&products_id=$pid&review_token=$token";
	$url = "store/review/$pid";
    header("Location: http://$host$path/$url");
    exit;
}

// Link to the gift certificate redemption page
if (isset($_GET['g'])) {

    $token = $_GET['g'];

    // Data validation -- drop undesired characters
    $token = ereg_replace("[^a-zA-Z0-9]", "", $token);

    // $url = "index.php?main_page=gv_redeem&gv_no=$token";
	$url = "store/redeem/$token";
    header("Location: http://$host$path/$url");
    exit;
}

// Default: Go to front page
header("Location: http://$host$path/");
