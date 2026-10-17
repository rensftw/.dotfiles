return {
    'sphamba/smear-cursor.nvim',
    event = 'VeryLazy',
    opts = {
        -- MiniAnimate owns movement within a buffer. Smear only transitions it
        -- cannot render, such as moving between splits or switching buffers.
        smear_between_buffers = true,
        smear_between_neighbor_lines = false,
        min_horizontal_distance_smear = math.huge,
        min_vertical_distance_smear = math.huge,
        smear_to_cmd = false,
        scroll_buffer_space = false,
    },
}
