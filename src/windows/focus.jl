#==# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   This file contains functions to handle focus in windows.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #==#

export accept_focus, has_focus, next_widget, process_focus, previous_widget,
       sync_cursor

"""
    function accept_focus(window::Window)

Check if the window `window` can accept focus and, if it can, then perform the
actions to change the focus.

 """
function accept_focus(window::Window)
    # Check if the window can have focus.
    if window.focusable
        # Move the window to the top and search for a widget that can hold the
        # focus.
        move_window_to_top(window)
        return true
    else
        return false
    end
end

"""
    function has_focus(window::Window, widget)

Return `true` if the widget `widget` is in focus on window `window`, or `false`
otherwise.

"""
function has_focus(window::Window, widget)
    @unpack widgets, focus_id = window

    focus_id <= 0 && return false
    return widgets[focus_id] === widget
end

"""
    function next_widget(window::Window)

Move the focus of window `window` to the next widget.

"""
function next_widget(window::Window)
    @unpack widgets, focus_id = window

    # Release the focus from previous widget.
    focus_id > 0 && release_focus(widgets[focus_id])

    # Search for the next widget that can handle the focus.
    for i = focus_id+1:length(widgets)
        if accept_focus(widgets[i])
            window.focus_id = i
            sync_cursor(window)
            return true
        end
    end

    # No more element could accept the focus.
    window.focus_id = 0
    sync_cursor(window)
    return false
end

"""
    function process_focus(window::Window, k::Keystroke)

Process the focus on window `window` due to keystroke `k`.

"""
function process_focus(window::Window, k::Keystroke)
    @unpack widgets, focus_id = window

    # If there is any element in focus, ask to process the keystroke.
    if focus_id > 0
        # If `process_focus` returns `false`, it means that the widget wants to
        # release the focus.
        if process_focus(widgets[focus_id],k)
            sync_cursor(window)
            return true
        end
    end

    # Otherwise, we must search another widget that can accept the focus.
    return next_widget(window)
end

"""
    function next_widget(window::Window)

Move the focus of window `window` to the previous widget.

"""
function previous_widget(window::Window)
    @unpack widgets, focus_id = window

    # Release the focus from previous widget.
    focus_id > 0  && release_focus(widgets[focus_id])
    focus_id == 0 && (focus_id = length(widgets))

    # Search for the next widget that can handle the focus.
    for i = focus_id-1:-1:1
        if accept_focus(widgets[i])
            window.focus_id = i
            sync_cursor(window)
            return true
        end
    end

    # No more element could accept the focus.
    window.focus_id = 0
    sync_cursor(window)
    return false
end

"""
    function sync_cursor(window::Window)

Synchronize the cursor to the position of the focused widget in window `window`.
This is necessary because all the operations are done in the buffer and then
copied to the view.

"""
function sync_cursor(window::Window)
    @unpack widgets, focus_id = window

    # If no widget is in focus, then move to the position (0,0).
    if focus_id <= 0
        wmove(window.view, 0, 0)
        return nothing
    else
        # Get the focused widget.
        widget = widgets[focus_id]

        # Get the cursor position on the `cwin` of the widget.
        cy,cx = _get_window_cur_pos(widget.cwin)
        by,bx = _get_window_coord(widget.cwin)

        # Compute the coordinates of the cursor with respect to the window.
        y = by + cy
        x = bx + cx

        # If the window has a border, then we must take this into account when
        # updating the cursor coordinates.
        if window.has_border
            y += 1
            x += 1
        end

        # Move the cursor.
        wmove(window.view, y, x)

        # TODO: Limit the cursor position to the edge of the screen.

        return nothing
    end
end