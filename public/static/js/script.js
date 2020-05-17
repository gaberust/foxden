$(document).ready(() => {

    let newest, oldest;

    function updateBounds() {
        if ($("#postFeed").children().length === 0) {
            newest = -1;
            oldest = 0;
        }
        else {
            newest = $("#postFeed").children(":first-child").attr("data-pid");
            oldest = $("#postFeed").children(":last-child").attr("data-pid");
        }

        if (oldest == 0) {
            $("#showMore").hide();
        }
    }

    updateBounds();

    $("#postButton").click(() => {
        $.post(
            "/post",
            {
                content: $("#newPost").val()
            },
            (data, status) => {
                if (data.success) {
                    $("#newPost").val("");
                }
                else {
                    alert(data.message);
                }
            }
        );
    });

    $("#showMore").click(() => {
        $.get(
            "/posts?lower=" + (parseInt(oldest) - 20) + "&upper=" + oldest,
            (data, status) => {
                $("#postFeed").append(data);
                updateBounds();
            }
        );
    });

    var updater = setInterval(() => {
        $.get(
            "/posts?lower=" + newest,
            (data, status) => {
                $("#postFeed").prepend(data);
                updateBounds();
            }
        );
    }, 3000);

});