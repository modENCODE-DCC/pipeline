<?
function get_datum_res($db, $id) {
  $sql = "SELECT
  data.data_id,
  data.heading,
  data.name,
  data.value,
  cvt.name AS type,
  COUNT(df.feature_id) AS num_features,
  pap.applied_protocol_id AS previous_applied_protocol_id,
  pp.name AS previous_protocol,
  nap.applied_protocol_id AS next_applied_protocol_id,
  np.name AS next_protocol
  FROM data
  LEFT JOIN cvterm cvt ON data.type_id = cvt.cvterm_id
  LEFT JOIN applied_protocol_data papd ON papd.data_id = data.data_id AND papd.direction = 'output'
  LEFT JOIN applied_protocol pap ON papd.applied_protocol_id = pap.applied_protocol_id
  LEFT JOIN protocol pp ON pap.protocol_id = pp.protocol_id

  LEFT JOIN applied_protocol_data napd ON napd.data_id = data.data_id AND napd.direction = 'input'
  LEFT JOIN applied_protocol nap ON napd.applied_protocol_id = nap.applied_protocol_id
  LEFT JOIN protocol np ON nap.protocol_id = np.protocol_id

  LEFT JOIN data_feature df ON data.data_id = df.data_id
  WHERE data.data_id = '" . pg_escape_string($id) . "'
  GROUP BY data.data_id, data.heading, data.name, data.value, pap.applied_protocol_id, pp.name, nap.applied_protocol_id, np.name, cvt.name";

  $res = pg_query($db, $sql);
  return $res;
}
function show_datum($id) {
  $db = pg_connect("host=smaug dbname=mepipe user=db_public password=ir84#4nm");
  if (!$db) { print "Couldn't open database connection."; exit; }

  $res = get_datum_res($db, $id);

  $row = pg_fetch_assoc($res);
  pg_result_seek($res, 0);
  print "<h2>Datum <i>" . $row["heading"] . " [" . $row["name"] . "]</i> (" . $row["data_id"] . ")</h2>\n";

  print "<h3>Values</h3>\n";
  print "<table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "  <tr><th>output from</th><th>datum</th><th>type</th><th>datum value</th><th># of features</th><th>used as input to</th></tr>\n";
    
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
  print "    <td>" . $row["heading"] . " [" . $row["name"] . "]</td>\n";
  print "    <td>" . $row["type"] . "</td>\n";
  print "    <td>" . $row["value"] . "</td>\n";
  print "    <td><a class=\"navigate\" href=\"index.php?data_feature_id=" . $row["data_id"] . "\">" . $row["num_features"] . "</a></td>\n";

  print "    <td>\n";
  pg_result_seek($res, 0);
  $row = pg_fetch_assoc($res);
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
  print "</table>\n";

  print "<h3>Attributes</h3>\n";
  $sql = "SELECT
  a.attribute_id,
  a.heading,
  a.name,
  a.value,
  a.rank
  FROM data_attribute da
  INNER JOIN attribute a ON da.attribute_id = a.attribute_id
  WHERE da.data_id = '" . pg_escape_string($id) . "'";
  $res = pg_query($db, $sql);

  print "<table cellpadding=\"0\" cellspacing=\"0\" class=\"dag\">\n";
  print "  <tr><th>attribute</th><th>value</th><th>rank</th></tr>\n";
  while ($row = pg_fetch_assoc($res)) {
    print "  <tr>\n";
    print "    <td>" . $row["heading"] . " [" . $row["name"] . "]</td>\n";
    print "    <td>" . $row["value"] . "</td>\n";
    print "    <td>" . $row["rank"] . "</td>\n";
    print "  </tr>\n";
  }
  print "</table>\n";

  pg_close($db);
}

?>
