<?
function show_experiments() {
  $db = pg_connect("host=smaug dbname=mepipe user=db_public password=ir84#4nm");
  if (!$db) { print "Couldn't open database connection."; exit; }

  $sql = "SELECT experiment_id, uniquename, description FROM experiment";
  $res = pg_query($db, $sql);

  print "  <table cellpadding=\"0\" cellspacing=\"0\" class=\"browse\">\n";
  print "    <tr><th>ID</th><th>name</th><th>description</th></tr>\n";
  while ($row = pg_fetch_assoc($res)) {
    if (!strlen($row["description"])) { $row["description"] = "(none)"; }
    print "    <tr>";
    print "<td>" . $row["experiment_id"] . "</td>";
    print "<td><a class=\"navigate\" href=\"index.php?experiment_id=" . $row["experiment_id"] . "\">" . $row["uniquename"] . "</a></td>";
    print "<td>" . $row["description"] . "</td>";
    print "</tr>\n";
  }
  print "</table>";

  pg_close($db);
}
?>
