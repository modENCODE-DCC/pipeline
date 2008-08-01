<?
function show_features($id) {
  $db = pg_connect("host=smaug dbname=mepipe user=db_public password=ir84#4nm");
  if (!$db) { print "Couldn't open database connection."; exit; }

  $sql = "SELECT 
  f.name,
  f.uniquename,
  cvt.name AS type,
  d.data_id,
  d.heading AS data_heading,
  d.name AS data_name
  FROM data d
  LEFT JOIN data_feature df ON df.data_id = d.data_id
  LEFT JOIN feature f ON df.feature_id = f.feature_id
  LEFT JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
  WHERE d.data_id  = '" . pg_escape_string($id) . "'";
  $res = pg_query($db, $sql);

  $row = pg_fetch_assoc($res);
  pg_result_seek($res, 0);
  print "<h2>Features for datum <i>" . $row["data_heading"] . " [" . $row["data_name"] . "]</i> (" . $row["data_id"] . ")</h2>\n";

  $num_rows = pg_num_rows($res);
  $first_row = true;
  print "<table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "  <tr><th>datum</th><th>name</th><th>uniquename</th><th>type</th></tr>\n";
  while ($row = pg_fetch_assoc($res)) {
    if ($first_row) {
      $first_row = false;
      print "  <tr>\n      <td valign=\"top\" rowspan=\"$num_rows\">";
      print "<a class=\"navigate\" href=\"index.php?data_id=" . $row["data_id"] . "\">" . $row["data_heading"] . " [" . $row["data_name"] . "]</a>";
      print "</td>\n";
    } else {
      print "  <tr>\n";
    }
    print "    <td>" . $row["name"] . "</td>\n";
    print "    <td>" . $row["uniquename"] . "</td>\n";
    print "    <td>" . $row["type"] . "</td>\n";
    print "  </tr>\n";
  }
  print "</table>";

  pg_close($db);
}
?>

