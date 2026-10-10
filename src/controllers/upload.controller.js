const cloudinary = require('../config/cloudinary');

const sharp = require('sharp');

const uploadFile = async (req, res) => {
    try {
        if (!req.file) {
            console.warn("[Upload] Warning: Request received with no file.");
            return res.status(400).json({ success: false, message: "No file uploaded" });
        }

        let resourceType = 'auto'; // Let Cloudinary auto-detect (image, video, raw)
        let uploadBuffer = req.file.buffer;

        console.log(`[Upload] Received file: "${req.file.originalname}" | Size: ${(req.file.size / 1024).toFixed(2)} KB | Mime: ${req.file.mimetype}`);

        if (req.file.mimetype.startsWith('video/')) {
            resourceType = 'video';
        } else if (req.file.mimetype.startsWith('audio/')) {
            resourceType = 'video'; // Cloudinary treats audio files as video resource_type
        } else if (req.file.mimetype.startsWith('image/')) {
            resourceType = 'image';
            
            // Compress the image before uploading to Cloudinary
            try {
                console.log(`[Upload] Compressing image...`);
                // Resize to max 1080px width/height and convert to webp with 80% quality
                uploadBuffer = await sharp(req.file.buffer)
                    .resize(1080, 1080, {
                        fit: sharp.fit.inside,
                        withoutEnlargement: true
                    })
                    .webp({ quality: 80 }) 
                    .toBuffer();
                
                console.log(`[Upload] Image compressed successfully. New Size: ${(uploadBuffer.length / 1024).toFixed(2)} KB (saved ${((1 - uploadBuffer.length/req.file.size)*100).toFixed(1)}%)`);
            } catch (err) {
                console.warn(`[Upload] Warning: Image compression failed, falling back to original buffer. Error:`, err.message);
            }
        }

        // Upload stream to Cloudinary
        console.log(`[Upload] Uploading to Cloudinary with resourceType: ${resourceType}...`);
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                resource_type: resourceType,
                folder: 'webrtc_chat_media',
            },
            (error, result) => {
                if (error) {
                    console.error("[Upload] Error: Cloudinary upload failed:", error);
                    return res.status(500).json({ success: false, message: "Failed to upload file to Cloudinary" });
                }

                console.log(`[Upload] Success! URL: ${result.secure_url}`);
                // Successfully uploaded
                return res.status(200).json({
                    success: true,
                    message: "File uploaded successfully",
                    url: result.secure_url,
                    format: result.format,
                    resource_type: result.resource_type
                });
            }
        );

        // Pipe the buffer to the stream
        uploadStream.end(uploadBuffer);

    } catch (error) {
        console.error("[Upload] Error in uploadController:", error);
        res.status(500).json({ success: false, message: "Internal server error during upload" });
    }
};

module.exports = {
    uploadFile
};
