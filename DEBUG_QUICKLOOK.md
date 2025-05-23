# Debugging QuickLook Extension

## Current Status
- ✅ Extension built successfully
- ✅ Installed to ~/Library/QuickLook/
- ✅ QuickLook recognizes it (qlmanage -p works)
- ❓ Unknown if it's actually loading our code

## Quick Debug Steps

1. **Check Console.app**
   - Open Console.app
   - Filter by "CalibreQuickLook" or "quicklook"
   - Look for errors when running: `qlmanage -p test-data/test_book.epub`

2. **Test Socket Connection**
   ```bash
   # Make sure service is running
   ./src/start_service.sh
   
   # Test socket directly
   echo '{"path": "'$PWD'/test-data/test_book.epub", "output_dir": "/tmp/ql-test"}' | nc -U /tmp/calibre-quicklook-socket
   ```

3. **Force QuickLook to Use Our Extension**
   ```bash
   # Remove competing extension temporarily
   mv ~/Library/QuickLook/EPUBQuickLook.qlgenerator ~/Desktop/
   qlmanage -r
   qlmanage -p test-data/test_book.epub
   ```

4. **Check Extension Loading**
   ```bash
   # See which generator is being used
   qlmanage -d 4 -p test-data/test_book.epub 2>&1 | grep -i generator
   ```

## Known Issues
- Might conflict with existing EPUBQuickLook.qlgenerator
- Socket connection might fail due to sandbox restrictions
- Service must be running for preview to work

## Next Steps if Not Working
1. Add more logging to Swift code
2. Test without sandbox restrictions
3. Consider packaging service with the extension