import { stringify } from 'csv-stringify/sync';
import PDFDocument from 'pdfkit';
export class ReportService {
    /**
     * Generates a CSV string from an array of FieldLogs
     */
    static generateCSV(logs) {
        const data = logs.map(log => ({
            'Log ID': log.id,
            'Student Name': log.user.name,
            'Student Email': log.user.email,
            'Title': log.title,
            'Status': log.status,
            'Timestamp': log.timestamp.toISOString(),
            'Location Name': log.locationName ?? 'N/A',
            'County': log.county ?? 'N/A',
            'Latitude': log.latitude ?? '',
            'Longitude': log.longitude ?? '',
            'Objectives': log.objectives ?? '',
            'Findings': log.findings ?? '',
        }));
        return stringify(data, { header: true });
    }
    /**
     * Generates a PDF buffer from an array of FieldLogs
     */
    static async generatePDF(logs, title = 'FieldTrack Supervisor Report') {
        return new Promise((resolve, reject) => {
            try {
                const doc = new PDFDocument({ margin: 50 });
                const buffers = [];
                doc.on('data', buffers.push.bind(buffers));
                doc.on('end', () => {
                    const pdfData = Buffer.concat(buffers);
                    resolve(pdfData);
                });
                // Header
                doc.fontSize(20).text(title, { align: 'center' });
                doc.moveDown();
                doc.fontSize(12).text(`Generated on: ${new Date().toLocaleString()}`, { align: 'center' });
                doc.moveDown(2);
                // Body
                if (logs.length === 0) {
                    doc.fontSize(14).text('No logs found for this period.', { align: 'center' });
                }
                else {
                    logs.forEach((log, index) => {
                        doc.fontSize(14).font('Helvetica-Bold').text(`${index + 1}. ${log.title}`);
                        doc.fontSize(10).font('Helvetica');
                        doc.text(`Student: ${log.user.name} (${log.user.email})`);
                        doc.text(`Date: ${log.timestamp.toLocaleString()}`);
                        doc.text(`Status: ${log.status}`);
                        doc.text(`Location: ${log.locationName ?? 'N/A'} (${log.county ?? 'N/A'})`);
                        if (log.description) {
                            doc.moveDown(0.5);
                            doc.text(`Description: ${log.description}`);
                        }
                        if (log.findings) {
                            doc.moveDown(0.5);
                            doc.text(`Findings: ${log.findings}`);
                        }
                        doc.moveDown(1.5);
                    });
                }
                // Footer
                const totalPages = doc.bufferedPageRange().count;
                for (let i = 0; i < totalPages; i++) {
                    doc.switchToPage(i);
                    doc.fontSize(8).text(`Page ${i + 1} of ${totalPages}`, 50, doc.page.height - 50, { align: 'center' });
                }
                doc.end();
            }
            catch (error) {
                reject(error);
            }
        });
    }
}
