<? print "<?xml version=\"1.0\"?>\n"; ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>modENCODE experiment browser</title>
  <link rel="stylesheet" href="style.css"/>
</head>
<body>
<h1><a href="/experiment_browser/">modENCODE experiment browser</a></h1>
<?
  include_once("show_experiments.php");
  include_once("show_experiment.php");
  include_once("show_data.php");
  include_once("show_features.php");
  include_once("show_applied_protocol.php");

  if (isset($_GET["experiment_id"])) {
    show_experiment($_GET["experiment_id"]);
  } elseif (isset($_GET["data_id"])) {
    show_datum($_GET["data_id"]);
  } elseif (isset($_GET["applied_protocol_id"])) {
    show_applied_protocol($_GET["applied_protocol_id"]);
  } elseif (isset($_GET["data_feature_id"])) {
    show_features($_GET["data_feature_id"]);
  } else {
    show_experiments();
  }

  function get_data_to($db, $applied_protocol_id, $direction) {
    $sql = "SELECT
    apd.data_id,
    data.heading,
    data.name
    FROM applied_protocol_data apd
    INNER JOIN data ON apd.data_id = data.data_id
    WHERE apd.direction = '$direction' AND apd.applied_protocol_id = $applied_protocol_id";
    $res = pg_query($db, $sql);
    $inputs = array();
    while ($row = pg_fetch_assoc($res)) {
      array_push($inputs, array(
        'id' => $row["data_id"],
        'heading' => $row["heading"],
        'name' => $row["name"]
      ));
    }
    return $inputs;
  }

?>
</body>
</html>
