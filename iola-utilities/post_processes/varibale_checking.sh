# Show variables and count for each file
for f in output*.nc; do
    echo "=== $f ==="
    vars=$(cdo showvar "$f")
    nvar=$(echo $vars | wc -w)
    echo "Variables ($nvar): $vars"
    echo ""
done

