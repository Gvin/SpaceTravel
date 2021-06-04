spacetravelcore.meta_set_object = function(meta, name, value)
    if (meta == nil) then
        error("Metadata is nil.", 2);
    elseif (name == nil or string.len(name) == 0) then
        error("Name is nil or empty.", 2);
    end

    meta:set_string(name, minetest.serialize(value));
end

spacetravelcore.meta_get_object = function(meta, name)
    if (meta == nil) then
        error("Metadata is nil.", 2);
    elseif (name == nil or string.len(name) == 0) then
        error("Name is nil or empty.", 2);
    end

    local str = meta:get_string(name);
    if (str == nil or string.len(str) == 0) then
        return nil;
    else
        return minetest.deserialize(str);
    end
end
