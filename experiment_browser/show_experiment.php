<?
function show_experiment($id) {
  $db = pg_connect("host=smaug dbname=mepipe user=db_public password=ir84#4nm");
  if (!$db) { print "Couldn't open database connection."; exit; }

  $sql = "SELECT 
  e.experiment_id,
  e.uniquename AS experiment,
  ap.applied_protocol_id AS first_applied_protocol_id,
  p.protocol_id,
  p.name AS protocol
  FROM experiment e
  INNER JOIN experiment_applied_protocol eap ON e.experiment_id = eap.experiment_id
  INNER JOIN applied_protocol ap ON eap.first_applied_protocol_id = ap.applied_protocol_id
  INNER JOIN protocol p ON ap.protocol_id = p.protocol_id
  WHERE e.experiment_id = '" . pg_escape_string($id) . "'";
  $res = pg_query($db, $sql);

  $row = pg_fetch_assoc($res);
  pg_result_seek($res, 0);
  print "<h2>Experiment <i>" . $row["experiment"] . "</i> (" . $row["experiment_id"] . ")</h2>\n";

  $num_rows = pg_num_rows($res);
  $first_row = true;
  print "  <table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "    <tr><th>experiment</th><th>inputs</th><th>first protocol</th><th>outputs</th></tr>\n";
  while ($row = pg_fetch_assoc($res)) {
    if ($first_row) {
      $first_row = false;
      print "    <tr>\n      <td rowspan=\"$num_rows\">";
      print $row["experiment"];
      print "</td>\n";
    } else {
      print "    <tr>\n";
    }

    $inputs = get_data_to($db, $row["first_applied_protocol_id"], "input");
    $outputs = get_data_to($db, $row["first_applied_protocol_id"], "output");
    
    print "      <td>";
    foreach ($inputs as $input) {
      print "<a class=\"navigate\" href=\"index.php?data_id=" . $input["id"] . "\">";
      print $input["heading"] . " [" . $input["name"] . "]</a><br/>";
    }
    print "</td>\n";
    print "      <td><a class=\"navigate\" href=\"index.php?applied_protocol_id=" . $row["first_applied_protocol_id"] . "\">" . $row["protocol"] . "</a></td>\n";
    print "      <td>";
    foreach ($outputs as $output) {
      print "<a class=\"navigate\" href=\"index.php?data_id=" . $output["id"] . "\">";
      print $output["heading"] . " [" . $output["name"] . "]</a><br/>";
    }
    print "</td>\n";
    print "    </tr>\n";
  }
  print "  </table>";

  pg_close($db);
}
?>
