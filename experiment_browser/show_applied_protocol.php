<?
include_once("show_data.php");
function show_applied_protocol($id) {
  $db = pg_connect("host=smaug dbname=mepipe user=db_public password=ir84#4nm");
  if (!$db) { print "Couldn't open database connection."; exit; }

  $sql = "SELECT 
  p.protocol_id,
  p.name AS protocol,
  ap.applied_protocol_id
  FROM applied_protocol ap
  INNER JOIN protocol p ON ap.protocol_id = p.protocol_id
  WHERE ap.applied_protocol_id = '" . pg_escape_string($id) . "'";
  $res = pg_query($db, $sql);

  $row = pg_fetch_assoc($res);
  pg_result_seek($res, 0);
  print "<h2>Applied Protocol <i>" . $row["protocol"] . "</i> (" . $row["applied_protocol_id"] . ")</h2>\n";

  $num_rows = pg_num_rows($res);
  $first_row = true;
  print "<table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "  <tr><th>inputs</th><th>applied protocol</th><th>outputs</th></tr>\n";
  while ($row = pg_fetch_assoc($res)) {
    print "  <tr>\n";

    $inputs = get_data_to($db, $row["applied_protocol_id"], "input");
    $outputs = get_data_to($db, $row["applied_protocol_id"], "output");
    
    print "    <td>";
    foreach ($inputs as $input) {
      print "<a class=\"navigate\" href=\"index.php?data_id=" . $input["id"] . "\">";
      print $input["heading"] . " [" . $input["name"] . "]</a><br/>";
    }
    print "</td>\n";
    print "    <td rowspan=\"$num_rows\">" . $row["protocol"] . " (" . $row["applied_protocol_id"] . ")</td>\n";
    print "    <td>";
    foreach ($outputs as $output) {
      print "<a class=\"navigate\" href=\"index.php?data_id=" . $output["id"] . "\">";
      print $output["heading"] . " [" . $output["name"] . "]</a><br/>";
    }
    print "</td>\n";
    print "</tr>\n";
  }
  print "</table>\n";

  $inputs = get_data_to($db, $id, "input");
  $outputs = get_data_to($db, $id, "output");
  print "<h3>Inputs</h2>\n";
  print "<table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "  <tr><th>output from</th><th>datum</th><th>datum value</th><th>used as input to</th></tr>\n";
  foreach ($inputs as $input) {
    $res = get_datum_res($db, $input["id"]);
    print "  <tr>\n";
    print "    <td>\n";
    $first_row = true;
    while ($row = pg_fetch_assoc($res)) {
      if (strlen($row["previous_protocol"])) {
        print "      <a class=\"navigate\" href=\"index.php?applied_protocol_id=" . $row["previous_applied_protocol_id"] . "\">";
        print $row["previous_protocol"] . " (" . $row["previous_applied_protocol_id"]  . ")</a><br/>\n";
      } elseif ($first_row) {
        $first_row = false;
        print "      (none)\n";
      }
    }
    print "    </td>\n";

    pg_result_seek($res, 0);
    $row = pg_fetch_assoc($res);
    print "    <td><a class=\"navigate\" href=\"index.php?data_id=" . $input["id"] . "\">" . $row["heading"] . " [" . $row["name"] . "]</a></td>\n";
    print "    <td>" . $row["value"] . "</td>\n";

    pg_result_seek($res, 0);
    print "    <td>\n";
    $first_row = true;
    while ($row = pg_fetch_assoc($res)) {
      if (strlen($row["next_protocol"])) {
        print "      <a class=\"navigate\" href=\"index.php?applied_protocol_id=" . $row["next_applied_protocol_id"] . "\">";
        print $row["next_protocol"] . " (" . $row["next_applied_protocol_id"]  . ")</a><br/>\n";
      } elseif ($first_row) {
        $first_row = false;
        print "      (none)\n";
      }
    }
    print "    </td>\n";
    print "  </tr>\n";
  }

  print "</table>\n";
  print "<h3>Outputs</h2>";
  print "<table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "  <tr><th>output from</th><th>datum</th><th>datum value</th><th>used as input to</th></tr>\n";
  foreach ($outputs as $output) {
    $res = get_datum_res($db, $output["id"]);
    print "  <tr>\n";
    print "    <td>\n";
    $first_row = true;
    while ($row = pg_fetch_assoc($res)) {
      if (strlen($row["previous_protocol"])) {
        print "      <a class=\"navigate\" href=\"index.php?applied_protocol_id=" . $row["previous_applied_protocol_id"] . "\">";
        print $row["previous_protocol"] . " (" . $row["previous_applied_protocol_id"]  . ")</a><br/>\n";
      } elseif ($first_row) {
        $first_row = false;
        print "      (none)\n";
      }
    }
    print "    </td>\n";

    pg_result_seek($res, 0);
    $row = pg_fetch_assoc($res);
    print "    <td><a class=\"navigate\" href=\"index.php?data_id=" . $output["id"] . "\">" . $row["heading"] . " [" . $row["name"] . "]</a></td>\n";
    print "    <td>" . $row["value"] . "</td>\n";

    pg_result_seek($res, 0);
    print "    <td>\n";
    $first_row = true;
    while ($row = pg_fetch_assoc($res)) {
      if (strlen($row["next_protocol"])) {
        print "      <a class=\"navigate\" href=\"index.php?applied_protocol_id=" . $row["next_applied_protocol_id"] . "\">";
        print $row["next_protocol"] . " (" . $row["next_applied_protocol_id"]  . ")</a><br/>\n";
      } elseif ($first_row) {
        $first_row = false;
        print "      (none)\n";
      }
    }
    print "    </td>\n";
    print "  </tr>\n";
  }
  print "</table>\n";

  pg_close($db);
}
?>
