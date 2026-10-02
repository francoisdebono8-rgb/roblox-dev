local Geometry = {}
local function visible(v,root)
    while v and v~=root.Parent do
        if v:IsA("GuiObject") and not v.Visible then return false end
        v=v.Parent
    end
    return true
end
function Geometry.check(root)
    local controls=0
    for _,v in ipairs(root:GetDescendants()) do
        if v:IsA("GuiObject") and visible(v,root) and v.Name~="Tooltip" then
            local left,right=v.AbsolutePosition.X,v.AbsolutePosition.X+v.AbsoluteSize.X
            assert(left>=root.AbsolutePosition.X-1 and right<=root.AbsolutePosition.X+root.AbsoluteSize.X+1,v:GetFullName().." horizontal overflow")
            if v:IsA("GuiButton") or v:IsA("TextBox") then
                controls+=1
                assert(v.AbsoluteSize.X>=28 and v.AbsoluteSize.Y>=28,v.Name.." undersized target")
            end
            if v:IsA("ScrollingFrame") then
                assert(v.ScrollingDirection==Enum.ScrollingDirection.Y,v.Name.." horizontal scrolling")
                assert(v.AbsoluteCanvasSize.X<=v.AbsoluteSize.X+1,v.Name.." horizontal canvas overflow")
            elseif v:IsA("TextLabel") and v.TextTruncate==Enum.TextTruncate.None and v.Text~="" then
                assert(v.TextBounds.X<=v.AbsoluteSize.X+1 and v.TextBounds.Y<=v.AbsoluteSize.Y+1,v.Name.." text overflow")
            end
        end
    end
    local body,footer=root.Body,root.Footer
    assert(body.AbsolutePosition.Y>=root.Header.AbsolutePosition.Y+root.Header.AbsoluteSize.Y-1,"Header overlap")
    assert(body.AbsolutePosition.Y+body.AbsoluteSize.Y<=footer.AbsolutePosition.Y+1,"Footer overlap")
    for _,b in ipairs(footer.Actions:GetChildren()) do
        if b:IsA("TextButton") then
            assert(b.AbsolutePosition.Y+b.AbsoluteSize.Y<=root.AbsolutePosition.Y+root.AbsoluteSize.Y,"Primary action clipped")
            assert(b.TextFits,b.Name.." primary text clipped")
        end
    end
    assert(root.Header.ProductTitle.TextFits,"Product title clipped")
    assert(root.Body.Collection.Visible or root.Body.Detail.Visible,"No work surface")
    for _,v in ipairs(root:GetDescendants()) do
        if v.Name=="ExpectedActual" and visible(v,root) then
            assert(math.abs(v.ExpectedCell.AbsoluteSize.Y-v.ActualCell.AbsoluteSize.Y)<=1,"Comparison cells misaligned")
        elseif v.Name=="Icon" and v.Parent.Name:match("^Nav") and visible(v,root) then
            local caption=v.Parent.Caption
            assert(math.abs(v.AbsolutePosition.Y+v.AbsoluteSize.Y/2-caption.AbsolutePosition.Y-caption.AbsoluteSize.Y/2)<=1,"Navigation icon misaligned")
        end
    end
    if root.AbsoluteSize.X<560 then assert(not root.Body.Navigation.Visible,"Narrow rail shown") end
    return controls
end
function Geometry.matrix(host)
    local original=host.Size
    local ok,err=pcall(function()
    for _,size in ipairs({Vector2.new(240,360),Vector2.new(320,640),Vector2.new(400,640),Vector2.new(560,640),Vector2.new(560,900)}) do
        host.Size=UDim2.fromOffset(size.X,size.Y)
        task.wait(0.25)
        local root=host.SchemaForgeUI
        assert(root.AbsoluteSize==size,"Wrong content size")
        local count=Geometry.check(root)
        print("[SchemaForgeUI][GEOMETRY PASS] "..settings().Studio.Theme.Name.." "..tostring(size).." controls="..count)
    end
    end)
    host.Size=original
    assert(ok,err)
end
return Geometry
